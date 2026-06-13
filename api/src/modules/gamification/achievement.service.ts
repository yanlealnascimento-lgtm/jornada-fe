import { achievementRepository } from './achievement.repository';
import { achievementEngine, AchievementContext } from './achievement.engine';
import { SEED_ACHIEVEMENTS, SEED_MISSION_ACHIEVEMENTS } from '../../config/seeds/achievement.seed';
import { UserModel } from '../users/user.model';
import { leagueService } from '../leagues/league.service';
import { getWeekKey } from '../../shared/utils/date.util';
import type { LeagueTier } from '../../shared/types';
import type { CreateAchievementInput, UpdateAchievementInput } from './achievement.validator';

export class AchievementService {

  async listActive() {
    return achievementRepository.findAllActive();
  }

  async listAdmin(filters: {
    is_active?: boolean;
    rarity?: string;
    trigger_type?: string;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    return achievementRepository.findAll(filters);
  }

  async getById(id: string) {
    const achievement = await achievementRepository.findById(id);
    if (!achievement) throw new Error('ACHIEVEMENT_NOT_FOUND');
    return achievement;
  }

  async create(input: CreateAchievementInput) {
    const existing = await achievementRepository.findByKey(input.key);
    if (existing) throw new Error('KEY_ALREADY_EXISTS');
    return achievementRepository.create(input);
  }

  async update(id: string, input: UpdateAchievementInput) {
    if (input.key) {
      const existing = await achievementRepository.findByKey(input.key);
      if (existing && existing._id.toString() !== id) {
        throw new Error('KEY_ALREADY_EXISTS');
      }
    }
    const achievement = await achievementRepository.update(id, input);
    if (!achievement) throw new Error('ACHIEVEMENT_NOT_FOUND');
    return achievement;
  }

  async delete(id: string) {
    const deleted = await achievementRepository.delete(id);
    if (!deleted) throw new Error('ACHIEVEMENT_NOT_FOUND');
    return { deleted: true };
  }

  async getStats() {
    return achievementRepository.getStats();
  }

  async runSeed() {
    const allSeeds = [...SEED_ACHIEVEMENTS, ...SEED_MISSION_ACHIEVEMENTS];
    return achievementRepository.seedMany(allSeeds as any[]);
  }

  async getUserAchievements(userId: string) {
    const [unlocked, locked] = await Promise.all([
      achievementRepository.findUserAchievements(userId),
      achievementRepository.findLockedForUser(userId),
    ]);
    return { unlocked, locked };
  }

  async checkAfterEvent(ctx: AchievementContext) {
    const newlyUnlocked = await achievementEngine.check(ctx);

    if (newlyUnlocked.length > 0) {
      const user = await UserModel.findById(ctx.userId);
      if (user) {
        let totalPF = 0;
        for (const ach of newlyUnlocked) {
          user.pf_total += ach.pf_reward;
          user.pf_weekly += ach.pf_reward;
          user.manas += ach.mana_reward;
          totalPF += ach.pf_reward;
        }
        await user.save();

        // Sync PF to league leaderboard
        if (totalPF > 0) {
          try {
            const tier = (user.league_tier as LeagueTier) || 'ruben';
            await leagueService.addPFToLeague(ctx.userId, tier, getWeekKey(), totalPF);
          } catch (_) {}
        }
      }
    }

    return newlyUnlocked;
  }
}

export const achievementService = new AchievementService();
