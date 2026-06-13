import { Request, Response } from 'express';
import { achievementService } from './achievement.service';
import { UserAchievementModel } from './user-achievement.model';
import { sendSuccess, sendError } from '../../shared/utils/response.util';
import { createAchievementSchema, updateAchievementSchema } from './achievement.validator';

export class AchievementController {

  // GET /api/v1/achievements[?user_id=xxx] — Lista pública (ativos)
  // When user_id is provided, each achievement includes is_unlocked and unlocked_at.
  async listActive(req: Request, res: Response) {
    try {
      const { user_id } = req.query;
      const achievements = await achievementService.listActive();

      if (user_id) {
        const unlockeds = await UserAchievementModel.find({ user_id: String(user_id) }).lean();
        const mapped = achievements.map(ac => {
          const unlocked = unlockeds.find(u => u.achievement_id.toString() === ac._id.toString());
          return {
            ...(ac as any).toObject(),
            is_unlocked: !!unlocked,
            unlocked_at: unlocked?.unlocked_at ?? null,
          };
        });
        return sendSuccess(res, mapped);
      }

      return sendSuccess(res, achievements);
    } catch (err) {
      return sendError(res, 'Erro ao buscar conquistas', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/admin/achievements — Lista admin (com filtros e paginação)
  async listAdmin(req: Request, res: Response) {
    try {
      const { is_active, rarity, trigger_type, search, page, limit } = req.query;

      const result = await achievementService.listAdmin({
        is_active:    is_active !== undefined ? is_active === 'true' : undefined,
        rarity:       rarity       as string | undefined,
        trigger_type: trigger_type as string | undefined,
        search:       search       as string | undefined,
        page:         page  ? Number(page)  : 1,
        limit:        limit ? Number(limit) : 50,
      });

      return sendSuccess(res, result);
    } catch (err) {
      return sendError(res, 'Erro ao buscar conquistas', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/admin/achievements/stats
  async getStats(_req: Request, res: Response) {
    try {
      const stats = await achievementService.getStats();
      return sendSuccess(res, stats);
    } catch (err) {
      return sendError(res, 'Erro ao buscar estatísticas', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/achievements/:id
  async getById(req: Request, res: Response) {
    try {
      const achievement = await achievementService.getById(req.params.id);
      return sendSuccess(res, achievement);
    } catch (err: unknown) {
      if ((err as Error).message === 'ACHIEVEMENT_NOT_FOUND')
        return sendError(res, 'Conquista não encontrada', 'ACHIEVEMENT_NOT_FOUND', 404);
      return sendError(res, 'Erro interno', 'INTERNAL_ERROR', 500);
    }
  }

  // POST /api/v1/admin/achievements
  async create(req: Request, res: Response) {
    try {
      const parsed = createAchievementSchema.safeParse(req.body);
      if (!parsed.success) {
        return sendError(res, parsed.error.errors[0].message, 'VALIDATION_ERROR', 422);
      }
      const achievement = await achievementService.create(parsed.data);
      return sendSuccess(res, achievement, 'Conquista criada com sucesso', 201);
    } catch (err: unknown) {
      if ((err as Error).message === 'KEY_ALREADY_EXISTS')
        return sendError(res, 'Já existe uma conquista com esta key', 'KEY_ALREADY_EXISTS', 409);
      return sendError(res, 'Erro ao criar conquista', 'INTERNAL_ERROR', 500);
    }
  }

  // PUT /api/v1/admin/achievements/:id
  async update(req: Request, res: Response) {
    try {
      const parsed = updateAchievementSchema.safeParse(req.body);
      if (!parsed.success) {
        return sendError(res, parsed.error.errors[0].message, 'VALIDATION_ERROR', 422);
      }
      const achievement = await achievementService.update(req.params.id, parsed.data);
      return sendSuccess(res, achievement, 'Conquista atualizada com sucesso');
    } catch (err: unknown) {
      if ((err as Error).message === 'ACHIEVEMENT_NOT_FOUND')
        return sendError(res, 'Conquista não encontrada', 'ACHIEVEMENT_NOT_FOUND', 404);
      if ((err as Error).message === 'KEY_ALREADY_EXISTS')
        return sendError(res, 'Já existe uma conquista com esta key', 'KEY_ALREADY_EXISTS', 409);
      return sendError(res, 'Erro ao atualizar conquista', 'INTERNAL_ERROR', 500);
    }
  }

  // DELETE /api/v1/admin/achievements/:id
  async delete(req: Request, res: Response) {
    try {
      await achievementService.delete(req.params.id);
      return sendSuccess(res, null, 'Conquista removida com sucesso');
    } catch (err: unknown) {
      if ((err as Error).message === 'ACHIEVEMENT_NOT_FOUND')
        return sendError(res, 'Conquista não encontrada', 'ACHIEVEMENT_NOT_FOUND', 404);
      return sendError(res, 'Erro ao remover conquista', 'INTERNAL_ERROR', 500);
    }
  }

  // GET /api/v1/achievements/user/:userId
  async getUserAchievements(req: Request, res: Response) {
    try {
      const result = await achievementService.getUserAchievements(req.params.userId);
      return sendSuccess(res, result);
    } catch (err) {
      return sendError(res, 'Erro ao buscar conquistas do usuário', 'INTERNAL_ERROR', 500);
    }
  }

  // POST /api/v1/admin/achievements/seed
  async seed(_req: Request, res: Response) {
    try {
      const result = await achievementService.runSeed();
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

export const achievementController = new AchievementController();
