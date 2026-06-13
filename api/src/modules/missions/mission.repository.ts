import { MissionTemplate, IMissionTemplate } from './mission-template.model';
import { UserMission, IUserMission } from './user-mission.model';
import mongoose from 'mongoose';

export class MissionRepository {
  // ─── Templates ──────────────────────────────────────────────────────────

  async findAllTemplates(filters: {
    cycle?: string;
    trigger?: string;
    difficulty?: string;
    is_active?: boolean;
    is_premium?: boolean;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const q: Record<string, unknown> = {};
    if (filters.is_active !== undefined) q.is_active = filters.is_active;
    if (filters.is_premium !== undefined) q.is_premium = filters.is_premium;
    if (filters.cycle) q.cycle = filters.cycle;
    if (filters.trigger) q.trigger = filters.trigger;
    if (filters.difficulty) q.difficulty = filters.difficulty;
    if (filters.search) {
      q.$or = [
        { title: { $regex: filters.search, $options: 'i' } },
        { description: { $regex: filters.search, $options: 'i' } },
      ];
    }
    const page = filters.page ?? 1;
    const limit = filters.limit ?? 50;
    const [templates, total] = await Promise.all([
      MissionTemplate.find(q)
        .sort({ sort_order: 1 })
        .skip((page - 1) * limit)
        .limit(limit),
      MissionTemplate.countDocuments(q),
    ]);
    return { templates, total };
  }

  async findActiveTemplates(cycle: string): Promise<IMissionTemplate[]> {
    return MissionTemplate.find({ cycle, is_active: true }).sort({ weight: -1 });
  }

  async findTemplateById(id: string) {
    return MissionTemplate.findById(id);
  }

  async createTemplate(data: Partial<IMissionTemplate>) {
    return MissionTemplate.create(data);
  }

  async updateTemplate(id: string, data: Partial<IMissionTemplate>) {
    return MissionTemplate.findByIdAndUpdate(id, { $set: data }, { new: true });
  }

  async deleteTemplate(id: string) {
    return !!(await MissionTemplate.findByIdAndDelete(id));
  }

  async getTemplateStats() {
    const result = await MissionTemplate.aggregate([
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          active: { $sum: { $cond: ['$is_active', 1, 0] } },
          daily: { $sum: { $cond: [{ $eq: ['$cycle', 'daily'] }, 1, 0] } },
          weekly: { $sum: { $cond: [{ $eq: ['$cycle', 'weekly'] }, 1, 0] } },
          premium: { $sum: { $cond: ['$is_premium', 1, 0] } },
          easy: { $sum: { $cond: [{ $eq: ['$difficulty', 'easy'] }, 1, 0] } },
          medium: { $sum: { $cond: [{ $eq: ['$difficulty', 'medium'] }, 1, 0] } },
          hard: { $sum: { $cond: [{ $eq: ['$difficulty', 'hard'] }, 1, 0] } },
        },
      },
    ]);
    return (
      result[0] ?? {
        total: 0,
        active: 0,
        daily: 0,
        weekly: 0,
        premium: 0,
        easy: 0,
        medium: 0,
        hard: 0,
      }
    );
  }

  async seedMany(items: Partial<IMissionTemplate>[]) {
    let created = 0,
      updated = 0;
    const errors: string[] = [];
    for (const item of items) {
      try {
        const exists = await MissionTemplate.findOne({ title: item.title, cycle: item.cycle });
        if (exists) {
          await MissionTemplate.findByIdAndUpdate(exists._id, { $set: item });
          updated++;
        } else {
          await MissionTemplate.create(item);
          created++;
        }
      } catch (e: unknown) {
        errors.push(`"${item.title}": ${(e as Error).message}`);
      }
    }
    return { created, updated, errors };
  }

  // ─── UserMissions ────────────────────────────────────────────────────────

  async findActiveForUser(userId: string): Promise<IUserMission[]> {
    return UserMission.find({
      user_id: new mongoose.Types.ObjectId(userId),
      status: 'active',
      cycle_end: { $gte: new Date() },
    }).sort({ cycle: 1, difficulty: 1 });
  }

  async findCompletedForUser(userId: string, limit = 20): Promise<IUserMission[]> {
    return UserMission.find({
      user_id: new mongoose.Types.ObjectId(userId),
      status: 'completed',
    })
      .sort({ completed_at: -1 })
      .limit(limit);
  }

  async createForUser(data: Partial<IUserMission>): Promise<IUserMission> {
    return UserMission.create(data);
  }

  async updateProgress(missionId: string, progress: number): Promise<IUserMission | null> {
    return UserMission.findByIdAndUpdate(missionId, { $set: { progress } }, { new: true });
  }

  async completeMission(missionId: string): Promise<IUserMission | null> {
    return UserMission.findByIdAndUpdate(
      missionId,
      { $set: { status: 'completed', completed_at: new Date() } },
      { new: true },
    );
  }

  async expireOldMissions(): Promise<number> {
    const result = await UserMission.updateMany(
      { status: 'active', cycle_end: { $lt: new Date() } },
      { $set: { status: 'expired' } },
    );
    return result.modifiedCount;
  }

  async hasActiveMissions(userId: string, cycle: string): Promise<boolean> {
    const count = await UserMission.countDocuments({
      user_id: new mongoose.Types.ObjectId(userId),
      cycle,
      status: 'active',
      cycle_end: { $gte: new Date() },
    });
    return count > 0;
  }

  async getUserMissionStats(userId: string) {
    const [activeCount, completedToday, completedTotal] = await Promise.all([
      UserMission.countDocuments({
        user_id: new mongoose.Types.ObjectId(userId),
        status: 'active',
        cycle_end: { $gte: new Date() },
      }),
      UserMission.countDocuments({
        user_id: new mongoose.Types.ObjectId(userId),
        status: 'completed',
        completed_at: { $gte: new Date(new Date().setHours(0, 0, 0, 0)) },
      }),
      UserMission.countDocuments({
        user_id: new mongoose.Types.ObjectId(userId),
        status: 'completed',
      }),
    ]);
    return { activeCount, completedToday, completedTotal };
  }
}

export const missionRepository = new MissionRepository();
