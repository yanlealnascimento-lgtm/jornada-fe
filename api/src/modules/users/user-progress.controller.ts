import { Request, Response, NextFunction } from 'express';
import { sendSuccess, sendError } from '../../shared/utils/response.util';
import { UserModel } from './user.model';
import { UserProgressModel } from './user-progress.model';
import { ExerciseModel } from '../content/exercise.model';
import { LeagueService } from '../leagues/league.service';
import { getWeekKey } from '../../shared/utils/date.util';
import mongoose from 'mongoose';

// PF necessário para cada nível (índice = nível, valor = PF acumulado)
const LEVEL_PF_TABLE = [0, 100, 250, 450, 700, 1000, 1400, 1900, 2500, 3200, 4000];
const MAX_LEVEL = LEVEL_PF_TABLE.length - 1;

function calcLevel(totalPf: number): number {
  let level = 1;
  for (let i = 1; i <= MAX_LEVEL; i++) {
    if (totalPf >= LEVEL_PF_TABLE[i]) level = i + 1;
    else break;
  }
  return Math.min(level, MAX_LEVEL + 1);
}

function pfForNextLevel(level: number): number {
  return LEVEL_PF_TABLE[level] ?? LEVEL_PF_TABLE[MAX_LEVEL];
}

export class UserProgressController {

  // GET /api/v1/users/:id/progress
  getProgress = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const user = await UserModel.findById(req.params.id).lean();
      if (!user) return sendError(res, 'Usuário não encontrado.', 'NOT_FOUND', 404);

      const totalPf = (user as any).pf_total ?? 0;
      const currentLevel = calcLevel(totalPf);
      const nextLevelPf = pfForNextLevel(currentLevel);

      const completedCount = await UserProgressModel.countDocuments({
        user_id: new mongoose.Types.ObjectId(req.params.id),
        status: 'completed',
      });

      const recentHistory = await UserProgressModel.find({
        user_id: new mongoose.Types.ObjectId(req.params.id),
        status: 'completed',
      })
        .sort({ completed_at: -1 })
        .limit(10)
        .lean();

      return sendSuccess(res, {
        userId: req.params.id,
        currentLevel,
        totalPf,
        pfForNextLevel: nextLevelPf,
        pfProgress: totalPf - (LEVEL_PF_TABLE[currentLevel - 1] ?? 0),
        pfNeeded: nextLevelPf - (LEVEL_PF_TABLE[currentLevel - 1] ?? 0),
        streakDays: (user as any).streak_current ?? 0,
        longestStreak: (user as any).streak_longest ?? 0,
        lastActivityDate: (user as any).last_activity_at ?? null,
        lessonsCompleted: completedCount,
        recentHistory,
        levelTable: LEVEL_PF_TABLE.map((pf, i) => ({ level: i + 1, pfRequired: pf })),
      }, 'Progresso recuperado.');
    } catch (error) { next(error); }
  };

  // POST /api/v1/users/:id/exercises/:exerciseId/complete
  completeExercise = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id: userId, exerciseId } = req.params;
      const { score = 100, time_spent_seconds = 0, mistakes_count = 0 } = req.body;

      const [user, exercise] = await Promise.all([
        UserModel.findById(userId),
        ExerciseModel.findById(exerciseId),
      ]);

      if (!user) return sendError(res, 'Usuário não encontrado.', 'NOT_FOUND', 404);
      if (!exercise) return sendError(res, 'Exercício não encontrado.', 'NOT_FOUND', 404);

      const pfEarned = Math.round(exercise.pf_reward * (score / 100));
      const prevPf = (user as any).pf_total ?? 0;
      const prevLevel = calcLevel(prevPf);

      // Atualizar PF e streak no usuário
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const lastActivity = (user as any).last_activity_at
        ? new Date((user as any).last_activity_at)
        : null;
      let streakCurrent = (user as any).streak_current ?? 0;

      if (lastActivity) {
        const lastDay = new Date(lastActivity);
        lastDay.setHours(0, 0, 0, 0);
        const diff = (today.getTime() - lastDay.getTime()) / 86400000;
        if (diff === 0) {
          // mesmo dia — não altera streak
        } else if (diff === 1) {
          streakCurrent += 1;
        } else {
          streakCurrent = 1;
        }
      } else {
        streakCurrent = 1;
      }

      const newPf = prevPf + pfEarned;
      const newLevel = calcLevel(newPf);
      const leveledUp = newLevel > prevLevel;

      await UserModel.findByIdAndUpdate(userId, {
        pf_total: newPf,
        level: newLevel,
        streak_current: streakCurrent,
        streak_longest: Math.max(streakCurrent, (user as any).streak_longest ?? 0),
        last_activity_at: new Date(),
      });

      // Registrar progresso (sem lesson_id obrigatório: usamos exerciseId como lesson_id temporário)
      const dummyObjectId = new mongoose.Types.ObjectId(exerciseId);
      await UserProgressModel.findOneAndUpdate(
        { user_id: new mongoose.Types.ObjectId(userId), lesson_id: dummyObjectId },
        {
          $set: {
            user_id: new mongoose.Types.ObjectId(userId),
            lesson_id: dummyObjectId,
            trail_id: dummyObjectId,
            unit_id: dummyObjectId,
            status: 'completed',
            score,
            pf_earned: pfEarned,
            mistakes_count,
            perfect: mistakes_count === 0,
            time_spent_seconds,
            completed_at: new Date(),
          },
        },
        { upsert: true, new: true }
      );

      // Add PF to user's league (fire-and-forget)
      if (pfEarned > 0) {
        try {
          const leagueService = new LeagueService();
          const tier = (user as any)?.league_tier || 'ruben';
          const weekKey = getWeekKey();
          await leagueService.addPFToLeague(userId, tier, weekKey, pfEarned);
        } catch (_) { /* silent — league PF is best-effort */ }
      }

      return sendSuccess(res, {
        pfEarned,
        totalPf: newPf,
        currentLevel: newLevel,
        leveledUp,
        streakDays: streakCurrent,
        pfForNextLevel: pfForNextLevel(newLevel),
      }, leveledUp ? `🎉 Parabéns! Você subiu para o nível ${newLevel}!` : 'Exercício concluído!');
    } catch (error) { next(error); }
  };
}
