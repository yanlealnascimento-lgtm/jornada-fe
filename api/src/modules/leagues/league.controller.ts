import { Request, Response } from 'express';
import { LeagueService } from './league.service';
import { LeagueModel, LeagueMemberModel } from './league.model';
import { LeagueTier, LEAGUE_TIERS_ORDERED } from '../../shared/types';
import { sendSuccess, sendError } from '../../shared/utils/response.util';

class LeagueController {
  private leagueService = new LeagueService();

  // ─── GET /api/v1/leagues/me ─────────────────────────────────────────
  async getUserLeague(req: Request, res: Response) {
    try {
      const userId = (req.headers['x-user-id'] as string) || (req.query.user_id as string);
      if (!userId) {
        return sendError(res, 'user_id é obrigatório (header X-User-Id ou query)', 'MISSING_USER_ID');
      }

      const data = await this.leagueService.getUserLeague(userId);
      return sendSuccess(res, data);
    } catch (err: any) {
      return sendError(res, err.message || 'Erro ao buscar liga do usuário', 'INTERNAL_ERROR', 500);
    }
  }

  // ─── POST /api/v1/leagues/xp ────────────────────────────────────────
  // Body: { user_id, pf_amount }
  // Auto-detects tier from UserModel.league_tier
  async addPF(req: Request, res: Response) {
    try {
      const { user_id, pf_amount } = req.body;
      if (!user_id || pf_amount == null) {
        return sendError(res, 'user_id e pf_amount são obrigatórios', 'MISSING_FIELDS');
      }

      // Import dynamically to avoid circular deps
      const { UserModel } = await import('../users/user.model');
      const { getWeekKey } = await import('../../shared/utils/date.util');

      const user = await UserModel.findById(user_id).select('league_tier').lean();
      if (!user) {
        return sendError(res, 'Usuário não encontrado', 'USER_NOT_FOUND', 404);
      }

      const tier = (user.league_tier as LeagueTier) || 'ruben';
      const weekKey = getWeekKey();

      const result = await this.leagueService.addPFToLeague(user_id, tier, weekKey, Number(pf_amount));

      // Also persist PF to user document (pf_total + pf_weekly)
      await UserModel.findByIdAndUpdate(user_id, {
        $inc: { pf_total: Number(pf_amount), pf_weekly: Number(pf_amount) },
      });

      return sendSuccess(res, { user_id, tier, pf_amount: Number(pf_amount), ...result }, 'PF adicionado');
    } catch (err: any) {
      return sendError(res, err.message || 'Erro ao adicionar PF', 'INTERNAL_ERROR', 500);
    }
  }

  // ─── POST /api/v1/leagues/join ──────────────────────────────────────
  // Body: { user_id, tier }
  async joinLeague(req: Request, res: Response) {
    try {
      const { user_id, tier } = req.body;
      if (!user_id || !tier) {
        return sendError(res, 'user_id e tier são obrigatórios', 'MISSING_FIELDS');
      }

      if (!LEAGUE_TIERS_ORDERED.includes(tier as LeagueTier)) {
        return sendError(res, `Tier inválido: ${tier}. Use: ${LEAGUE_TIERS_ORDERED.join(', ')}`, 'INVALID_TIER');
      }

      await this.leagueService.assignUserToLeague(user_id, tier as LeagueTier);
      return sendSuccess(res, { user_id, tier }, 'Usuário adicionado à liga', 201);
    } catch (err: any) {
      return sendError(res, err.message || 'Erro ao entrar na liga', 'INTERNAL_ERROR', 500);
    }
  }

  // ─── GET /api/v1/admin/leagues/stats ────────────────────────────────
  async getAdminStats(req: Request, res: Response) {
    try {
      const leagues = await LeagueModel.find().lean();
      const activeCount = leagues.filter((l) => l.is_active).length;

      // Per-tier breakdown
      const tierStats = await Promise.all(
        LEAGUE_TIERS_ORDERED.map(async (tier) => {
          const tierLeagues = leagues.filter((l) => l.tier === tier);
          const memberCount = await LeagueMemberModel.countDocuments({ tier });
          const realCount = await LeagueMemberModel.countDocuments({ tier, is_mock: false });
          return {
            tier,
            league_count: tierLeagues.length,
            total_members: memberCount,
            real_members: realCount,
            mock_members: memberCount - realCount,
          };
        }),
      );

      const totalMembers = tierStats.reduce((sum, t) => sum + t.total_members, 0);

      return sendSuccess(res, {
        total_leagues: leagues.length,
        active_leagues: activeCount,
        total_members: totalMembers,
        tiers: tierStats,
      });
    } catch (err: any) {
      return sendError(res, err.message || 'Erro ao buscar stats das ligas', 'INTERNAL_ERROR', 500);
    }
  }

  // ─── POST /api/v1/admin/leagues/seed ────────────────────────────────
  async seed(req: Request, res: Response) {
    try {
      const result = await this.leagueService.seedCurrentWeek();
      return sendSuccess(res, result, 'Seed de ligas executado', 201);
    } catch (err: any) {
      return sendError(res, err.message || 'Erro ao fazer seed das ligas', 'INTERNAL_ERROR', 500);
    }
  }

  // ─── POST /api/v1/admin/leagues/process-weekly ─────────────────────
  async processWeekly(req: Request, res: Response) {
    try {
      const result = await this.leagueService.processWeeklyPromotion();
      return sendSuccess(res, result, 'Processamento semanal executado');
    } catch (err: any) {
      return sendError(res, err.message || 'Erro no processamento semanal', 'INTERNAL_ERROR', 500);
    }
  }
}

export const leagueController = new LeagueController();
