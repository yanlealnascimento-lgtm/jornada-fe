import { Request, Response } from 'express';
import { missionService } from './mission.service';
import { sendSuccess, sendError } from '../../shared/utils/response.util';

export class MissionController {
  // ─── Public (App) ────────────────────────────────────────────────────────

  // GET /api/v1/missions?user_id=X
  async getUserMissions(req: Request, res: Response) {
    try {
      const userId = req.query.user_id as string;
      if (!userId) return sendError(res, 'user_id é obrigatório', 'VALIDATION_ERROR', 400);
      const result = await missionService.getUserMissions(userId);
      return sendSuccess(res, result);
    } catch (err) {
      return sendError(res, 'Erro ao buscar missões', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/missions/history?user_id=X
  async getHistory(req: Request, res: Response) {
    try {
      const userId = req.query.user_id as string;
      if (!userId) return sendError(res, 'user_id é obrigatório', 'VALIDATION_ERROR', 400);
      const result = await missionService.getMissionHistory(userId);
      return sendSuccess(res, result);
    } catch (err) {
      return sendError(res, 'Erro ao buscar histórico', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/missions/stats?user_id=X
  async getUserStats(req: Request, res: Response) {
    try {
      const userId = req.query.user_id as string;
      if (!userId) return sendError(res, 'user_id é obrigatório', 'VALIDATION_ERROR', 400);
      const result = await missionService.getUserStats(userId);
      return sendSuccess(res, result);
    } catch (err) {
      return sendError(res, 'Erro ao buscar stats', 'INTERNAL_ERROR', 500);
    }
  }

  // POST /api/v1/missions/event
  async processEvent(req: Request, res: Response) {
    try {
      const { user_id, event, value, isPerfect, streakDays } = req.body;
      if (!user_id || !event)
        return sendError(res, 'user_id e event são obrigatórios', 'VALIDATION_ERROR', 400);
      const result = await missionService.processEvent({
        userId: user_id,
        event,
        value,
        isPerfect,
        streakDays,
      });
      return sendSuccess(res, result);
    } catch (err) {
      return sendError(res, 'Erro ao processar evento', 'INTERNAL_ERROR', 500);
    }
  }

  // ─── Admin ───────────────────────────────────────────────────────────────

  // GET /api/v1/admin/missions/templates
  async listTemplates(req: Request, res: Response) {
    try {
      const { cycle, trigger, difficulty, is_active, is_premium, search, page, limit } = req.query;
      const result = await missionService.listTemplates({
        cycle: cycle as string | undefined,
        trigger: trigger as string | undefined,
        difficulty: difficulty as string | undefined,
        is_active: is_active !== undefined ? is_active === 'true' : undefined,
        is_premium: is_premium !== undefined ? is_premium === 'true' : undefined,
        search: search as string | undefined,
        page: page ? Number(page) : 1,
        limit: limit ? Number(limit) : 50,
      });
      return sendSuccess(res, result);
    } catch (err) {
      return sendError(res, 'Erro ao buscar templates', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/admin/missions/templates/stats
  async getStats(_req: Request, res: Response) {
    try {
      const stats = await missionService.getStats();
      return sendSuccess(res, stats);
    } catch (err) {
      return sendError(res, 'Erro ao buscar estatísticas', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/admin/missions/templates/:id
  async getTemplateById(req: Request, res: Response) {
    try {
      const template = await missionService.getTemplateById(req.params.id);
      return sendSuccess(res, template);
    } catch (err: unknown) {
      if ((err as Error).message === 'TEMPLATE_NOT_FOUND')
        return sendError(res, 'Template não encontrado', 'TEMPLATE_NOT_FOUND', 404);
      return sendError(res, 'Erro interno', 'INTERNAL_ERROR', 500);
    }
  }

  // POST /api/v1/admin/missions/templates
  async createTemplate(req: Request, res: Response) {
    try {
      const template = await missionService.createTemplate(req.body);
      return sendSuccess(res, template, 'Template criado com sucesso', 201);
    } catch (err) {
      return sendError(res, 'Erro ao criar template', 'INTERNAL_ERROR', 500);
    }
  }

  // PUT /api/v1/admin/missions/templates/:id
  async updateTemplate(req: Request, res: Response) {
    try {
      const template = await missionService.updateTemplate(req.params.id, req.body);
      return sendSuccess(res, template, 'Template atualizado com sucesso');
    } catch (err: unknown) {
      if ((err as Error).message === 'TEMPLATE_NOT_FOUND')
        return sendError(res, 'Template não encontrado', 'TEMPLATE_NOT_FOUND', 404);
      return sendError(res, 'Erro ao atualizar template', 'INTERNAL_ERROR', 500);
    }
  }

  // DELETE /api/v1/admin/missions/templates/:id
  async deleteTemplate(req: Request, res: Response) {
    try {
      await missionService.deleteTemplate(req.params.id);
      return sendSuccess(res, null, 'Template removido com sucesso');
    } catch (err: unknown) {
      if ((err as Error).message === 'TEMPLATE_NOT_FOUND')
        return sendError(res, 'Template não encontrado', 'TEMPLATE_NOT_FOUND', 404);
      return sendError(res, 'Erro ao remover template', 'INTERNAL_ERROR', 500);
    }
  }

  // POST /api/v1/admin/missions/templates/seed
  async seed(_req: Request, res: Response) {
    try {
      const result = await missionService.runSeed();
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

export const missionController = new MissionController();
