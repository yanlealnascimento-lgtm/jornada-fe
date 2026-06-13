import { Request, Response, NextFunction } from 'express';
import { LeagueService } from '../leagues/league.service';
import { StreakService } from './streak.service';
import { sendSuccess } from '../../shared/utils/response.util';
import { UserModel } from '../users/user.model';
import { AchievementModel } from './achievement.model';
import { UserAchievementModel } from './user-achievement.model';

export class GamificationController {
  private leagueService = new LeagueService();
  private streakService = new StreakService();

  getLeagueDetails = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user?.userId as string;
      const leagueStats = await this.leagueService.getUserLeague(userId);
      return sendSuccess(res, leagueStats, 'Ranking da liga.');
    } catch (error) {
      next(error);
    }
  };

  buyStreakFreeze = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user?.userId as string;
      const result = await this.streakService.useStreakFreeze(userId);
      if (result.success) {
         return sendSuccess(res, result, 'Freeze ativado com sucesso.');
      }
      return sendSuccess(res, result, 'Manás insuficientes ou erro ao comprar freeze.', 400);
    } catch (error) {
      next(error);
    }
  };

  getGlobalLeaderboard = async (req: Request, res: Response, next: NextFunction) => {
     try {
       const topUsers = await UserModel.find({ is_active: true, role: 'user' })
                                        .sort({ pf_total: -1 })
                                        .limit(100)
                                        .select('name avatar_url pf_total level league_tier streak_current');
       return sendSuccess(res, topUsers, 'Leaderboard global.');
     } catch(err) {
       next(err);
     }
  }

  getAchievements = async (req: Request, res: Response, next: NextFunction) => {
      try {
        const userId = req.user?.userId as string;
        const allAchievements = await AchievementModel.find({ is_active: true }).lean();
        const userUnlockeds = await UserAchievementModel.find({ user_id: userId }).lean();
        
        const mapped = allAchievements.map(ac => {
            const unlocked = userUnlockeds.find(u => u.achievement_id.toString() === ac._id.toString());
            return {
                ...ac,
                is_unlocked: !!unlocked,
                unlocked_at: unlocked?.unlocked_at
            }
        });

        return sendSuccess(res, mapped, 'Conquistas carregadas.');
      } catch (err) {
          next(err);
      }
  }
}
