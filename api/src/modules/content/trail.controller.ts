import { Request, Response } from 'express';
import { trailService } from './trail.service';
import { sendSuccess, sendError } from '../../shared/utils/response.util';
import { createTrailSchema, updateTrailSchema, reorderTrailsSchema } from './trail.validator';
import { UnitModel } from './unit.model';
import { LessonModel } from './lesson.model';
import { ExerciseModel } from './exercise.model';

export class TrailController {

  // GET /api/v1/trails — Lista pública (app Flutter)
  async listPublished(req: Request, res: Response) {
    try {
      const company_id = req.query.company_id as string | undefined;
      const { trails, total } = await trailService.listPublishedTrails({ company_id });
      return sendSuccess(res, { trails, total });
    } catch (err) {
      return sendError(res, 'Erro ao buscar trilhas', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/admin/trails — Lista admin (com filtros e paginação)
  async listAdmin(req: Request, res: Response) {
    try {
      const {
        is_published, is_core, is_premium,
        denomination, company_id, search,
        page, limit,
      } = req.query;

      const result = await trailService.listTrails({
        is_published:  is_published !== undefined ? is_published === 'true' : undefined,
        is_core:       is_core      !== undefined ? is_core      === 'true' : undefined,
        is_premium:    is_premium   !== undefined ? is_premium   === 'true' : undefined,
        denomination:  denomination as string | undefined,
        company_id:    company_id   as string | undefined,
        search:        search       as string | undefined,
        page:          page  ? Number(page)  : 1,
        limit:         limit ? Number(limit) : 50,
      });

      return sendSuccess(res, result);
    } catch (err) {
      return sendError(res, 'Erro ao buscar trilhas', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/admin/trails/stats
  async getStats(_req: Request, res: Response) {
    try {
      const stats = await trailService.getStats();
      return sendSuccess(res, stats);
    } catch (err) {
      return sendError(res, 'Erro ao buscar estatísticas', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/trails/:id
  async getById(req: Request, res: Response) {
    try {
      const trail = await trailService.getTrailById(req.params.id);
      return sendSuccess(res, trail);
    } catch (err: unknown) {
      if ((err as Error).message === 'TRAIL_NOT_FOUND')
        return sendError(res, 'Trilha não encontrada', 'TRAIL_NOT_FOUND', 404);
      return sendError(res, 'Erro interno', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/trails/slug/:slug
  async getBySlug(req: Request, res: Response) {
    try {
      const trail = await trailService.getTrailBySlug(req.params.slug);
      return sendSuccess(res, trail);
    } catch (err: unknown) {
      if ((err as Error).message === 'TRAIL_NOT_FOUND')
        return sendError(res, 'Trilha não encontrada', 'TRAIL_NOT_FOUND', 404);
      return sendError(res, 'Erro interno', 'INTERNAL_ERROR', 500);
    }
  }

  // POST /api/v1/admin/trails
  async create(req: Request, res: Response) {
    try {
      const parsed = createTrailSchema.safeParse(req.body);
      if (!parsed.success) {
        return sendError(res, parsed.error.errors[0].message, 'VALIDATION_ERROR', 422);
      }
      const trail = await trailService.createTrail(parsed.data);
      return sendSuccess(res, trail, 'Trilha criada com sucesso', 201);
    } catch (err: unknown) {
      if ((err as Error).message === 'SLUG_ALREADY_EXISTS')
        return sendError(res, 'Já existe uma trilha com este slug', 'SLUG_ALREADY_EXISTS', 409);
      return sendError(res, 'Erro ao criar trilha', 'INTERNAL_ERROR', 500);
    }
  }

  // PUT /api/v1/admin/trails/:id
  async update(req: Request, res: Response) {
    try {
      const parsed = updateTrailSchema.safeParse(req.body);
      if (!parsed.success) {
        return sendError(res, parsed.error.errors[0].message, 'VALIDATION_ERROR', 422);
      }
      const trail = await trailService.updateTrail(req.params.id, parsed.data);
      return sendSuccess(res, trail, 'Trilha atualizada com sucesso');
    } catch (err: unknown) {
      if ((err as Error).message === 'TRAIL_NOT_FOUND')
        return sendError(res, 'Trilha não encontrada', 'TRAIL_NOT_FOUND', 404);
      return sendError(res, 'Erro ao atualizar trilha', 'INTERNAL_ERROR', 500);
    }
  }

  // DELETE /api/v1/admin/trails/:id
  async delete(req: Request, res: Response) {
    try {
      await trailService.deleteTrail(req.params.id);
      return sendSuccess(res, null, 'Trilha removida com sucesso');
    } catch (err: unknown) {
      if ((err as Error).message === 'TRAIL_NOT_FOUND')
        return sendError(res, 'Trilha não encontrada', 'TRAIL_NOT_FOUND', 404);
      return sendError(res, 'Erro ao remover trilha', 'INTERNAL_ERROR', 500);
    }
  }

  // PATCH /api/v1/admin/trails/reorder
  async reorder(req: Request, res: Response) {
    try {
      const parsed = reorderTrailsSchema.safeParse(req.body);
      if (!parsed.success) {
        return sendError(res, 'Formato inválido para reordenação', 'VALIDATION_ERROR', 422);
      }
      const result = await trailService.reorderTrails(parsed.data);
      return sendSuccess(res, result, `${result.reordered} trilhas reordenadas`);
    } catch (err) {
      return sendError(res, 'Erro ao reordenar trilhas', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/trails/:id/units — Retorna units com lessons embutidas (app Home)
  async getUnitsWithLessons(req: Request, res: Response) {
    try {
      const trailId = req.params.id;
      const trail = await trailService.getTrailById(trailId);

      const units = await UnitModel.find({ trail_id: trailId, is_published: true })
        .sort({ order: 1 })
        .lean();

      const unitIds = units.map(u => u._id);
      const lessons = await LessonModel.find({ unit_id: { $in: unitIds }, is_published: true })
        .sort({ order: 1 })
        .lean();

      const result = units.map(unit => ({
        ...unit,
        id: unit._id,
        lessons: lessons
          .filter(l => l.unit_id.toString() === unit._id.toString())
          .map(l => ({ ...l, id: l._id })),
      }));

      return sendSuccess(res, {
        trail: { ...trail.toObject?.() ?? trail, id: (trail as any)._id },
        units: result,
      });
    } catch (err: unknown) {
      if ((err as Error).message === 'TRAIL_NOT_FOUND')
        return sendError(res, 'Trilha não encontrada', 'TRAIL_NOT_FOUND', 404);
      return sendError(res, 'Erro ao buscar unidades', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/exercises/lesson/:lessonId — Exercícios de uma lição específica
  async getExercisesByLesson(req: Request, res: Response) {
    try {
      const exercises = await ExerciseModel.find({
        lesson_id: req.params.lessonId,
        is_active: true,
      })
        .sort({ order: 1 })
        .lean();

      return sendSuccess(res, exercises.map(e => ({ ...e, id: e._id })));
    } catch (err) {
      return sendError(res, 'Erro ao buscar exercícios', 'INTERNAL_ERROR', 500);
    }
  }

  // POST /api/v1/admin/trails/seed
  async seed(_req: Request, res: Response) {
    try {
      const result = await trailService.runSeed();
      return sendSuccess(
        res,
        result,
        `Seed concluído: ${result.created} criadas, ${result.updated} atualizadas`,
        201,
      );
    } catch (err) {
      return sendError(res, 'Erro ao executar seed', 'INTERNAL_ERROR', 500);
    }
  }
}

export const trailController = new TrailController();
