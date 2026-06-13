import mongoose, { Schema, Document } from 'mongoose';

export interface IUserAchievement extends Document {
  user_id: mongoose.Types.ObjectId;
  achievement_id: mongoose.Types.ObjectId;
  unlocked_at: Date;
  notified: boolean;
}

const UserAchievementSchema = new Schema<IUserAchievement>(
  {
    user_id: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    achievement_id: { type: Schema.Types.ObjectId, ref: 'Achievement', required: true },
    unlocked_at: { type: Date, default: Date.now },
    notified: { type: Boolean, default: false },
  },
  { timestamps: true }
);

UserAchievementSchema.index({ user_id: 1, achievement_id: 1 }, { unique: true });

export const UserAchievementModel = mongoose.model<IUserAchievement>('UserAchievement', UserAchievementSchema);
