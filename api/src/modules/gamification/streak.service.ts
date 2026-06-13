import { UserModel } from '../users/user.model';
import { isToday, isYesterday } from '../../shared/utils/date.util';

export interface StreakResult {
  maintained: boolean;
  broken: boolean;
  streak: number;
  isNewRecord: boolean;
}

export class StreakService {
  async updateStreak(userId: string): Promise<StreakResult> {
    const user = await UserModel.findById(userId);
    if (!user) throw new Error('User not found');

    const lastActivity = user.streak_last_activity;
    let newStreak = user.streak_current;
    let broken = false;
    let maintained = true;

    if (lastActivity) {
      if (isToday(lastActivity)) {
        // Já fez hoje, só mantém
      } else if (isYesterday(lastActivity)) {
        // Fez ontem, logo a streak aumenta
        newStreak++;
      } else {
        // Pulou ao menos um dia — calcular quantos dias perdidos
        const lastDay = new Date(lastActivity);
        lastDay.setHours(0, 0, 0, 0);
        const now = new Date();
        now.setHours(0, 0, 0, 0);
        const daysMissed = Math.floor((now.getTime() - lastDay.getTime()) / 86400000) - 1;

        if (daysMissed === 1 && user.streak_freeze_count >= 1) {
          // Escudo cobre exatamente 1 dia perdido — consumir e incrementar por hoje
          user.streak_freeze_count -= 1;
          newStreak++;
        } else {
          // Perdeu 2+ dias OU sem escudo — ofensiva zerada
          broken = true;
          maintained = false;
          newStreak = 1;
        }
      }
    } else {
      // Primeira atividade
      newStreak = 1;
    }

    const isNewRecord = newStreak > user.streak_longest;
    user.streak_current = newStreak;
    user.streak_last_activity = new Date();
    
    if (isNewRecord) {
      user.streak_longest = newStreak;
    }

    await user.save();
    return { maintained, broken, streak: newStreak, isNewRecord };
  }

  async hasActivityToday(userId: string): Promise<boolean> {
    const user = await UserModel.findById(userId).select('streak_last_activity');
    if (!user || !user.streak_last_activity) return false;
    return isToday(user.streak_last_activity);
  }

  async useStreakFreeze(userId: string): Promise<{ success: boolean, remaining: number, reason?: string }> {
     const SHIELD_COST = 200; // 200 Mana
     const MAX_SHIELDS = 1;

     const user = await UserModel.findById(userId);
     if (!user) return { success: false, remaining: 0, reason: 'user_not_found' };

     if (user.streak_freeze_count >= MAX_SHIELDS) {
        return { success: false, remaining: user.streak_freeze_count, reason: 'max_shields_reached' };
     }

     if (user.manas < SHIELD_COST) {
        return { success: false, remaining: user.streak_freeze_count, reason: 'not_enough_mana' };
     }

     user.manas -= SHIELD_COST;
     user.streak_freeze_count = 1;
     await user.save();
     return { success: true, remaining: user.streak_freeze_count };
  }

  async getUsersAtRiskToday(): Promise<string[]> {
    const now = new Date();
    const startOfToday = new Date(now.setHours(0,0,0,0));
    
    // Usuários com streak > 0, mas cuja ultima atividade foi anterior a hoje
    const users = await UserModel.find({
      streak_current: { $gt: 0 },
      streak_last_activity: { $lt: startOfToday }
    }).select('_id');
    
    return users.map(u => u._id.toString());
  }
}
