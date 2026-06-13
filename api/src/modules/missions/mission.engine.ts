import { missionRepository } from './mission.repository';
import { MissionTrigger } from './mission-template.model';
import mongoose from 'mongoose';

export interface MissionEventContext {
  userId: string;
  event: MissionTrigger;
  value?: number;
  isPerfect?: boolean;
  streakDays?: number;
}

export class MissionEngine {
  async processEvent(
    ctx: MissionEventContext,
  ): Promise<{ updated: string[]; completed: string[] }> {
    const updated: string[] = [];
    const completed: string[] = [];

    const activeMissions = await missionRepository.findActiveForUser(ctx.userId);
    const relevant = activeMissions.filter((m) => this.isRelevant(m.trigger, ctx.event));

    for (const mission of relevant) {
      const increment = this.calculateIncrement(mission.trigger, ctx);
      if (increment <= 0) continue;

      const newProgress = Math.min(mission.progress + increment, mission.target);
      await missionRepository.updateProgress(
        (mission._id as mongoose.Types.ObjectId).toString(),
        newProgress,
      );
      updated.push((mission._id as mongoose.Types.ObjectId).toString());

      if (newProgress >= mission.target && mission.status === 'active') {
        await missionRepository.completeMission(
          (mission._id as mongoose.Types.ObjectId).toString(),
        );
        completed.push((mission._id as mongoose.Types.ObjectId).toString());
      }
    }

    return { updated, completed };
  }

  private isRelevant(trigger: string, event: string): boolean {
    if (trigger === event) return true;
    if (trigger === 'lesson_count' && event === 'perfect_lesson') return true;
    return false;
  }

  private calculateIncrement(trigger: string, ctx: MissionEventContext): number {
    switch (trigger) {
      case 'lesson_count':
        return 1;
      case 'perfect_lesson':
        return ctx.isPerfect ? 1 : 0;
      case 'pf_earn':
        return ctx.value ?? 0;
      case 'trail_progress':
        return 1;
      case 'study_complete':
        return 1;
      case 'league_xp':
        return ctx.value ?? 0;
      case 'invite_friend':
        return 1;
      case 'review_lesson':
        return 1;
      case 'streak_maintain':
        return 1;
      default:
        return 0;
    }
  }
}

export const missionEngine = new MissionEngine();
