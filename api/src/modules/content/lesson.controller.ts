import { Request, Response } from 'express';
import { LessonModel } from './lesson.model';
import { ExerciseModel } from './exercise.model';
import { sendSuccess, sendError } from '../../shared/utils/response.util';

export class LessonController {
  // GET /api/v1/admin/lessons?unit_id=X
  async list(req: Request, res: Response) {
    try {
      const { unit_id, trail_id } = req.query;
      const filter: Record<string, unknown> = {};
      if (unit_id) filter.unit_id = unit_id;
      if (trail_id) filter.trail_id = trail_id;
      if (!unit_id && !trail_id) return sendError(res, 'unit_id ou trail_id é obrigatório', 'VALIDATION_ERROR', 400);

      const lessons = await LessonModel.find(filter).sort({ order: 1 }).lean();
      const lessonIds = lessons.map(l => l._id);

      // Aggregate total PF and actual exercise count per lesson (source of truth)
      const exAgg = await ExerciseModel.aggregate([
        { $match: { lesson_id: { $in: lessonIds } } },
        {
          $group: {
            _id: '$lesson_id',
            total_pf: { $sum: '$pf_reward' },
            count: { $sum: 1 },
          },
        },
      ]);
      const pfMap = new Map(exAgg.map((r: any) => [String(r._id), r.total_pf]));
      const countMap = new Map(exAgg.map((r: any) => [String(r._id), r.count]));

      // Sync stale total_exercises counters in background (fire-and-forget)
      for (const r of exAgg) {
        const lesson = lessons.find(l => String(l._id) === String(r._id));
        if (lesson && lesson.total_exercises !== r.count) {
          LessonModel.findByIdAndUpdate(r._id, { $set: { total_exercises: r.count } }).catch(() => {});
        }
      }

      return sendSuccess(res, lessons.map(l => ({
        ...l,
        id: l._id,
        exercises_pf_total: pfMap.get(String(l._id)) || 0,
        total_exercises: countMap.get(String(l._id)) ?? l.total_exercises,
      })));
    } catch (err) {
      return sendError(res, 'Erro ao buscar lições', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/admin/lessons/:id
  async getById(req: Request, res: Response) {
    try {
      const lesson = await LessonModel.findById(req.params.id).lean();
      if (!lesson) return sendError(res, 'Lição não encontrada', 'NOT_FOUND', 404);
      return sendSuccess(res, { ...lesson, id: lesson._id });
    } catch (err) {
      return sendError(res, 'Erro ao buscar lição', 'INTERNAL_ERROR', 500);
    }
  }

  // POST /api/v1/admin/lessons
  async create(req: Request, res: Response) {
    try {
      const { unit_id, trail_id, title, subtitle, order, pf_reward, pf_perfect_bonus, estimated_minutes, lesson_type, is_published } = req.body;
      if (!unit_id || !trail_id || !title) return sendError(res, 'unit_id, trail_id e title são obrigatórios', 'VALIDATION_ERROR', 400);

      const maxOrder = await LessonModel.findOne({ unit_id }).sort({ order: -1 }).select('order').lean();
      const lesson = await LessonModel.create({
        unit_id,
        trail_id,
        title,
        subtitle: subtitle || '',
        order: order ?? ((maxOrder?.order ?? 0) + 1),
        pf_reward: pf_reward ?? 10,
        pf_perfect_bonus: pf_perfect_bonus ?? 5,
        estimated_minutes: estimated_minutes ?? 5,
        lesson_type: lesson_type || 'standard',
        total_exercises: 0,
        is_published: is_published ?? true,
      });

      // Update trail total_lessons
      const totalLessons = await LessonModel.countDocuments({ trail_id });
      const { TrailModel: Trail } = await import('./trail.model');
      await Trail.findByIdAndUpdate(trail_id, { $set: { total_lessons: totalLessons } });

      return sendSuccess(res, { ...lesson.toObject(), id: lesson._id }, 'Lição criada', 201);
    } catch (err) {
      return sendError(res, 'Erro ao criar lição', 'INTERNAL_ERROR', 500);
    }
  }

  // PUT /api/v1/admin/lessons/:id
  async update(req: Request, res: Response) {
    try {
      const lesson = await LessonModel.findByIdAndUpdate(req.params.id, { $set: req.body }, { new: true });
      if (!lesson) return sendError(res, 'Lição não encontrada', 'NOT_FOUND', 404);
      return sendSuccess(res, { ...lesson.toObject(), id: lesson._id }, 'Lição atualizada');
    } catch (err) {
      return sendError(res, 'Erro ao atualizar lição', 'INTERNAL_ERROR', 500);
    }
  }

  // PUT /api/v1/admin/lessons/:id/stages
  // Saves stage assignments AND syncs exercise.lesson_id so both systems stay consistent.
  async updateStages(req: Request, res: Response) {
    try {
      const lessonId = req.params.id;
      const { stages, stages_count } = req.body as {
        stages: Array<{ stage_index: number; exercise_ids: string[]; stage_type?: string }>;
        stages_count: number;
      };

      if (!stages || stages_count == null) {
        return sendError(res, 'stages e stages_count são obrigatórios', 'VALIDATION_ERROR', 400);
      }

      // Collect all exercise IDs being assigned to this lesson via stages
      const allStageExIds = stages.flatMap(s => s.exercise_ids);

      // Find all exercises that currently have lesson_id = this lesson (may be losing assignment)
      const previouslyLinked = await ExerciseModel.find({ lesson_id: lessonId }).select('_id').lean();
      const previousIds = previouslyLinked.map((e: any) => String(e._id));

      // Exercises removed from stages → clear lesson_id
      const removedIds = previousIds.filter(id => !allStageExIds.includes(id));
      if (removedIds.length > 0) {
        await ExerciseModel.updateMany(
          { _id: { $in: removedIds } },
          { $unset: { lesson_id: '' } },
        );
      }

      // Exercises added to stages → set lesson_id
      if (allStageExIds.length > 0) {
        await ExerciseModel.updateMany(
          { _id: { $in: allStageExIds } },
          { $set: { lesson_id: lessonId } },
        );
      }

      // Save stages to lesson + update total_exercises counter
      const lesson = await LessonModel.findByIdAndUpdate(
        lessonId,
        { $set: { stages, stages_count, total_exercises: allStageExIds.length } },
        { new: true },
      );
      if (!lesson) return sendError(res, 'Lição não encontrada', 'NOT_FOUND', 404);

      return sendSuccess(res, { ...lesson.toObject(), id: lesson._id }, 'Etapas salvas com sucesso');
    } catch (err) {
      return sendError(res, 'Erro ao salvar etapas', 'INTERNAL_ERROR', 500);
    }
  }

  // DELETE /api/v1/admin/lessons/:id
  async delete(req: Request, res: Response) {
    try {
      const lesson = await LessonModel.findByIdAndDelete(req.params.id);
      if (!lesson) return sendError(res, 'Lição não encontrada', 'NOT_FOUND', 404);

      // Update trail total_lessons
      const totalLessons = await LessonModel.countDocuments({ trail_id: lesson.trail_id });
      const { TrailModel: Trail } = await import('./trail.model');
      await Trail.findByIdAndUpdate(lesson.trail_id, { $set: { total_lessons: totalLessons } });

      return sendSuccess(res, null, 'Lição removida');
    } catch (err) {
      return sendError(res, 'Erro ao remover lição', 'INTERNAL_ERROR', 500);
    }
  }
}

export const lessonController = new LessonController();
