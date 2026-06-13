import mongoose, { Document, Schema } from 'mongoose';

export interface IUserStudyProgress extends Document {
  user_id:   mongoose.Types.ObjectId;
  study_id:  mongoose.Types.ObjectId;
  study_slug: string;
  lessons_completed: number[];
  current_lesson:    number;
  status: 'not_started' | 'in_progress' | 'completed';
  pf_earned:   number;
  mana_earned: number;
  started_at:    Date;
  completed_at?: Date;
  last_activity: Date;
}

const UserStudyProgressSchema = new Schema<IUserStudyProgress>({
  user_id:    { type: Schema.Types.ObjectId, ref: 'User', required: true },
  study_id:   { type: Schema.Types.ObjectId, ref: 'BibleStudy', required: true },
  study_slug: { type: String, required: true },
  lessons_completed: [Number],
  current_lesson:    { type: Number, default: 0 },
  status: { type: String, enum: ['not_started', 'in_progress', 'completed'], default: 'not_started' },
  pf_earned:   { type: Number, default: 0 },
  mana_earned: { type: Number, default: 0 },
  started_at:    { type: Date, default: Date.now },
  completed_at:  Date,
  last_activity: { type: Date, default: Date.now },
}, { timestamps: true });

UserStudyProgressSchema.index({ user_id: 1, study_id: 1 }, { unique: true });
UserStudyProgressSchema.index({ user_id: 1, started_at: 1 });

export const UserStudyProgressModel = mongoose.model<IUserStudyProgress>('UserStudyProgress', UserStudyProgressSchema);
