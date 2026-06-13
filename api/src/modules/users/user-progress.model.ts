import mongoose, { Schema, Document } from 'mongoose';

export interface IUserProgress extends Document {
  user_id: mongoose.Types.ObjectId;
  lesson_id: mongoose.Types.ObjectId;
  trail_id: mongoose.Types.ObjectId;
  unit_id: mongoose.Types.ObjectId;
  
  status: 'not_started' | 'in_progress' | 'completed';
  
  score: number;
  pf_earned: number;
  mistakes_count: number;
  perfect: boolean;
  
  time_spent_seconds: number;
  started_at: Date;
  completed_at?: Date;
  
  next_review_at?: Date;
  review_count: number;
  
  createdAt: Date;
  updatedAt: Date;
}

const UserProgressSchema = new Schema<IUserProgress>(
  {
    user_id: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    lesson_id: { type: Schema.Types.ObjectId, ref: 'Lesson', required: true },
    trail_id: { type: Schema.Types.ObjectId, ref: 'Trail', required: true },
    unit_id: { type: Schema.Types.ObjectId, ref: 'Unit', required: true },
    
    status: { type: String, enum: ['not_started', 'in_progress', 'completed'], default: 'not_started' },
    
    score: { type: Number, default: 0 },
    pf_earned: { type: Number, default: 0 },
    mistakes_count: { type: Number, default: 0 },
    perfect: { type: Boolean, default: false },
    
    time_spent_seconds: { type: Number, default: 0 },
    started_at: { type: Date, default: Date.now },
    completed_at: { type: Date },
    
    next_review_at: { type: Date },
    review_count: { type: Number, default: 0 },
  },
  { timestamps: true }
);

UserProgressSchema.index({ user_id: 1, lesson_id: 1 }, { unique: true });
UserProgressSchema.index({ user_id: 1, trail_id: 1 });
UserProgressSchema.index({ user_id: 1, completed_at: -1 });
UserProgressSchema.index({ next_review_at: 1 });

export const UserProgressModel = mongoose.model<IUserProgress>('UserProgress', UserProgressSchema);
