import { AchievementModel, IAchievement } from './achievement.model';
import { UserAchievementModel, IUserAchievement } from './user-achievement.model';
import mongoose from 'mongoose';

export class AchievementRepository {

  async findAll(filters: {
    is_active?: boolean;
    rarity?: string;
    trigger_type?: string;
    search?: string;
    page?: number;
    limit?: number;
  }): Promise<{ achievements: IAchievement[]; total: number }> {
    const query: Record<string, unknown> = {};

    if (filters.is_active !== undefined) query.is_active = filters.is_active;
    if (filters.rarity)                  query.rarity = filters.rarity;
    if (filters.trigger_type)            query['trigger.type'] = filters.trigger_type;
    if (filters.search) {
      query.$or = [
        { name:        { $regex: filters.search, $options: 'i' } },
        { description: { $regex: filters.search, $options: 'i' } },
        { key:         { $regex: filters.search, $options: 'i' } },
      ];
    }

    const page  = filters.page  ?? 1;
    const limit = filters.limit ?? 50;
    const skip  = (page - 1) * limit;

    const [achievements, total] = await Promise.all([
      AchievementModel.find(query)
        .sort({ sort_order: 1, createdAt: 1 })
        .skip(skip)
        .limit(limit),
      AchievementModel.countDocuments(query),
    ]);

    return { achievements, total };
  }

  async findAllActive(): Promise<IAchievement[]> {
    return AchievementModel.find({ is_active: true }).sort({ sort_order: 1 });
  }

  async findByKey(key: string): Promise<IAchievement | null> {
    return AchievementModel.findOne({ key });
  }

  async findById(id: string): Promise<IAchievement | null> {
    return AchievementModel.findById(id);
  }

  async create(data: Partial<IAchievement>): Promise<IAchievement> {
    return AchievementModel.create(data);
  }

  async update(id: string, data: Partial<IAchievement>): Promise<IAchievement | null> {
    return AchievementModel.findByIdAndUpdate(id, { $set: data }, { new: true, runValidators: true });
  }

  async delete(id: string): Promise<boolean> {
    const result = await AchievementModel.findByIdAndDelete(id);
    return !!result;
  }

  async getStats(): Promise<{
    total: number;
    active: number;
    inactive: number;
    common: number;
    rare: number;
    epic: number;
  }> {
    const result = await AchievementModel.aggregate([
      {
        $group: {
          _id: null,
          total:    { $sum: 1 },
          active:   { $sum: { $cond: ['$is_active', 1, 0] } },
          inactive: { $sum: { $cond: [{ $not: '$is_active' }, 1, 0] } },
          common:   { $sum: { $cond: [{ $eq: ['$rarity', 'common'] }, 1, 0] } },
          rare:     { $sum: { $cond: [{ $eq: ['$rarity', 'rare'] }, 1, 0] } },
          epic:     { $sum: { $cond: [{ $eq: ['$rarity', 'epic'] }, 1, 0] } },
        },
      },
    ]);

    const stats = result[0] ?? { total: 0, active: 0, inactive: 0, common: 0, rare: 0, epic: 0 };
    delete stats._id;
    return stats;
  }

  async seedMany(items: Partial<IAchievement>[]): Promise<{
    created: number;
    updated: number;
    errors: string[];
  }> {
    let created = 0;
    let updated = 0;
    const errors: string[] = [];

    for (const item of items) {
      try {
        const result = await AchievementModel.findOneAndUpdate(
          { key: item.key },
          { $set: item },
          { upsert: true, new: true, setDefaultsOnInsert: true },
        );
        if (result.createdAt.getTime() === result.updatedAt.getTime()) {
          created++;
        } else {
          updated++;
        }
      } catch (err: unknown) {
        errors.push(`Erro em "${item.key}": ${(err as Error).message}`);
      }
    }

    return { created, updated, errors };
  }

  async userHasAchievement(userId: string, achievementId: string): Promise<boolean> {
    const exists = await UserAchievementModel.findOne({
      user_id: new mongoose.Types.ObjectId(userId),
      achievement_id: new mongoose.Types.ObjectId(achievementId),
    });
    return !!exists;
  }

  async grantToUser(userId: string, achievementId: string): Promise<IUserAchievement> {
    return UserAchievementModel.create({
      user_id: new mongoose.Types.ObjectId(userId),
      achievement_id: new mongoose.Types.ObjectId(achievementId),
    });
  }

  async findUserAchievements(userId: string): Promise<IUserAchievement[]> {
    return UserAchievementModel.find({
      user_id: new mongoose.Types.ObjectId(userId),
    }).populate('achievement_id');
  }

  async findLockedForUser(userId: string): Promise<IAchievement[]> {
    const unlocked = await UserAchievementModel.find({
      user_id: new mongoose.Types.ObjectId(userId),
    }).select('achievement_id');

    const unlockedIds = unlocked.map((ua) => ua.achievement_id);

    return AchievementModel.find({
      _id: { $nin: unlockedIds },
      is_active: true,
    }).sort({ sort_order: 1 });
  }
}

export const achievementRepository = new AchievementRepository();
