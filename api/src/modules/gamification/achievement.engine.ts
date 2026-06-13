import { IAchievement } from './achievement.model';
import { achievementRepository } from './achievement.repository';

export interface AchievementContext {
  userId: string;
  lessonsCompleted?: number;
  streakDays?: number;
  trailsCompleted?: number;
  leagueRank?: number;
  inviteCount?: number;
  pfTotal?: number;
  level?: number;
  perfectLesson?: boolean;
}

export class AchievementEngine {

  async check(ctx: AchievementContext): Promise<IAchievement[]> {
    const allActive = await achievementRepository.findAllActive();
    const newlyUnlocked: IAchievement[] = [];

    for (const achievement of allActive) {
      if (!this.evaluateTrigger(achievement, ctx)) continue;

      const alreadyHas = await achievementRepository.userHasAchievement(
        ctx.userId,
        achievement._id.toString(),
      );
      if (alreadyHas) continue;

      await achievementRepository.grantToUser(ctx.userId, achievement._id.toString());
      newlyUnlocked.push(achievement);
    }

    return newlyUnlocked;
  }

  private evaluateTrigger(achievement: IAchievement, ctx: AchievementContext): boolean {
    const { type, value } = achievement.trigger;

    switch (type) {
      case 'lesson_count':
        return (ctx.lessonsCompleted ?? 0) >= value;

      case 'streak_days':
        return (ctx.streakDays ?? 0) >= value;

      case 'trail_complete':
        return (ctx.trailsCompleted ?? 0) >= value;

      case 'league_rank':
        return ctx.leagueRank !== undefined && ctx.leagueRank > 0 && ctx.leagueRank <= value;

      case 'invite_count':
        return (ctx.inviteCount ?? 0) >= value;

      case 'pf_total':
        return (ctx.pfTotal ?? 0) >= value;

      case 'level':
        return (ctx.level ?? 0) >= value;

      case 'perfect_lesson':
        return ctx.perfectLesson === true;

      default:
        return false;
    }
  }
}

export const achievementEngine = new AchievementEngine();
