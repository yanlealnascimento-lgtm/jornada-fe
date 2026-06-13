import mongoose, { Document, Schema } from 'mongoose';

export interface IUserLessonProgress extends Document {
  user_id:   mongoose.Types.ObjectId;
  lesson_id: mongoose.Types.ObjectId;
  unit_id:   mongoose.Types.ObjectId;
  trail_id:  mongoose.Types.ObjectId;

  stages_total:     number;
  stages_completed: number;
  current_stage:    number;

  status: 'not_started' | 'in_progress' | 'completed';

  pf_earned:   number;
  mana_earned: number;
  perfect:     boolean;

  started_at:    Date;
  completed_at?: Date;
  last_activity: Date;
}

const UserLessonProgressSchema = new Schema<IUserLessonProgress>({
  user_id:   { type: Schema.Types.ObjectId, ref: 'User',   required: true },
  lesson_id: { type: Schema.Types.ObjectId, ref: 'Lesson', required: true },
  unit_id:   { type: Schema.Types.ObjectId, ref: 'Unit',   required: true },
  trail_id:  { type: Schema.Types.ObjectId, ref: 'Trail',  required: true },

  stages_total:     { type: Number, required: true, min: 1, max: 5 },
  stages_completed: { type: Number, default: 0 },
  current_stage:    { type: Number, default: 0 },

  status: { type: String, enum: ['not_started', 'in_progress', 'completed'], default: 'not_started' },

  pf_earned:   { type: Number, default: 0 },
  mana_earned: { type: Number, default: 0 },
  perfect:     { type: Boolean, default: true },

  started_at:    { type: Date, default: Date.now },
  completed_at:  Date,
  last_activity: { type: Date, default: Date.now },
}, { timestamps: true });

UserLessonProgressSchema.index({ user_id: 1, lesson_id: 1 }, { unique: true });
UserLessonProgressSchema.index({ user_id: 1, trail_id: 1 });
UserLessonProgressSchema.index({ user_id: 1, status: 1 });

export const UserLessonProgressModel = mongoose.model<IUserLessonProgress>('UserLessonProgress', UserLessonProgressSchema);
