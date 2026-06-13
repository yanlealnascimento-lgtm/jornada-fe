import { Request, Response } from 'express';
import { UnitModel } from './unit.model';
import { LessonModel } from './lesson.model';
import { sendSuccess, sendError } from '../../shared/utils/response.util';

export class UnitController {
  // GET /api/v1/admin/units?trail_id=X
  async list(req: Request, res: Response) {
    try {
      const { trail_id } = req.query;
      if (!trail_id) return sendError(res, 'trail_id é obrigatório', 'VALIDATION_ERROR', 400);
      const units = await UnitModel.find({ trail_id }).sort({ order: 1 }).lean();

      // Attach lesson count per unit
      const unitIds = units.map(u => u._id);
      const lessonCounts = await LessonModel.aggregate([
        { $match: { unit_id: { $in: unitIds } } },
        { $group: { _id: '$unit_id', count: { $sum: 1 } } },
      ]);
      const countMap = new Map(lessonCounts.map(lc => [lc._id.toString(), lc.count]));

      const result = units.map(u => ({
        ...u,
        id: u._id,
        lesson_count: countMap.get(u._id.toString()) || 0,
      }));

      return sendSuccess(res, result);
    } catch (err) {
      return sendError(res, 'Erro ao buscar unidades', 'INTERNAL_ERROR', 500);
    }
  }

  // POST /api/v1/admin/units
  async create(req: Request, res: Response) {
    try {
      const { trail_id, title, description, order, icon_name, color_hex, unlock_condition, is_published } = req.body;
      if (!trail_id || !title) return sendError(res, 'trail_id e title são obrigatórios', 'VALIDATION_ERROR', 400);

      const maxOrder = await UnitModel.findOne({ trail_id }).sort({ order: -1 }).select('order').lean();
      const unit = await UnitModel.create({
        trail_id,
        title,
        description: description || '',
        order: order ?? ((maxOrder?.order ?? 0) + 1),
        icon_name: icon_name || 'book',
        color_hex: color_hex || '#4A90E2',
        unlock_condition: unlock_condition || { type: 'free' },
        is_published: is_published ?? true,
      });

      // Update trail total_units
      const totalUnits = await UnitModel.countDocuments({ trail_id });
      const { TrailModel: Trail } = await import('./trail.model');
      await Trail.findByIdAndUpdate(trail_id, { $set: { total_units: totalUnits } });

      return sendSuccess(res, { ...unit.toObject(), id: unit._id }, 'Unidade criada', 201);
    } catch (err) {
      return sendError(res, 'Erro ao criar unidade', 'INTERNAL_ERROR', 500);
    }
  }

  // PUT /api/v1/admin/units/:id
  async update(req: Request, res: Response) {
    try {
      const unit = await UnitModel.findByIdAndUpdate(req.params.id, { $set: req.body }, { new: true });
      if (!unit) return sendError(res, 'Unidade não encontrada', 'NOT_FOUND', 404);
      return sendSuccess(res, { ...unit.toObject(), id: unit._id }, 'Unidade atualizada');
    } catch (err) {
      return sendError(res, 'Erro ao atualizar unidade', 'INTERNAL_ERROR', 500);
    }
  }

  // DELETE /api/v1/admin/units/:id
  async delete(req: Request, res: Response) {
    try {
      const unit = await UnitModel.findByIdAndDelete(req.params.id);
      if (!unit) return sendError(res, 'Unidade não encontrada', 'NOT_FOUND', 404);

      // Delete associated lessons
      await LessonModel.deleteMany({ unit_id: unit._id });

      // Update trail counts
      const totalUnits = await UnitModel.countDocuments({ trail_id: unit.trail_id });
      const totalLessons = await LessonModel.countDocuments({ trail_id: unit.trail_id });
      const { TrailModel: Trail } = await import('./trail.model');
      await Trail.findByIdAndUpdate(unit.trail_id, { $set: { total_units: totalUnits, total_lessons: totalLessons } });

      return sendSuccess(res, null, 'Unidade removida');
    } catch (err) {
      return sendError(res, 'Erro ao remover unidade', 'INTERNAL_ERROR', 500);
    }
  }
}

export const unitController = new UnitController();
