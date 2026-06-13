import { UserStudyProgressModel } from './user-study-progress.model';

export class StudyAccessService {
  private readonly FREE_WEEKLY_LIMIT = 2;

  async canAccess(userId: string, studyIsPremium: boolean, userIsPremium: boolean) {
    if (userIsPremium) return { allowed: true };
    if (studyIsPremium) return { allowed: false, reason: 'PREMIUM_REQUIRED' };

    const used = await this._countThisWeek(userId);
    if (used >= this.FREE_WEEKLY_LIMIT) {
      return {
        allowed: false,
        reason: 'FREE_WEEKLY_LIMIT_REACHED',
        freeUsed: used,
        freeLimit: this.FREE_WEEKLY_LIMIT,
        resetsAt: this._nextMonday(),
      };
    }
    return { allowed: true, freeUsed: used, freeLimit: this.FREE_WEEKLY_LIMIT };
  }

  private async _countThisWeek(userId: string): Promise<number> {
    const mon = this._lastMonday();
    return UserStudyProgressModel.countDocuments({
      user_id: userId,
      started_at: { $gte: mon },
      status: { $in: ['in_progress', 'completed'] },
    });
  }

  private _lastMonday(): Date {
    const d = new Date();
    const day = d.getDay();
    const diff = day === 0 ? 6 : day - 1;
    d.setDate(d.getDate() - diff);
    d.setHours(0, 0, 0, 0);
    return d;
  }

  private _nextMonday(): Date {
    const d = new Date();
    const day = d.getDay();
    const diff = day === 0 ? 1 : 8 - day;
    d.setDate(d.getDate() + diff);
    d.setHours(0, 0, 0, 0);
    return d;
  }
}

export const studyAccessService = new StudyAccessService();
