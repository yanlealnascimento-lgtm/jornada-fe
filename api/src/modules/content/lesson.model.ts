import mongoose, { Schema, Document } from 'mongoose';

export interface ILessonStage {
  stage_index: number;
  exercise_ids: mongoose.Types.ObjectId[];
  stage_type?: string;
}

export interface ILesson extends Document {
  unit_id: mongoose.Types.ObjectId;
  trail_id: mongoose.Types.ObjectId;

  title: string;
  subtitle?: string;
  order: number;

  pf_reward: number;
  pf_perfect_bonus: number;
  estimated_minutes: number;

  lesson_type: 'standard' | 'review' | 'challenge' | 'story';

  story_character_id?: mongoose.Types.ObjectId;
  story_text?: string;

  total_exercises: number;
  is_published: boolean;

  // Stages system
  stages: ILessonStage[];
  stages_count: number;

  createdAt: Date;
  updatedAt: Date;
}

const LessonSchema = new Schema<ILesson>(
  {
    unit_id: { type: Schema.Types.ObjectId, ref: 'Unit', required: true },
    trail_id: { type: Schema.Types.ObjectId, ref: 'Trail', required: true },
    
    title: { type: String, required: true },
    subtitle: { type: String },
    order: { type: Number, required: true },
    
    pf_reward: { type: Number, default: 10 },
    pf_perfect_bonus: { type: Number, default: 5 },
    estimated_minutes: { type: Number, default: 5 },
    
    lesson_type: { type: String, enum: ['standard', 'review', 'challenge', 'story'], default: 'standard' },
    
    story_character_id: { type: Schema.Types.ObjectId, ref: 'Character' },
    story_text: { type: String },
    
    total_exercises: { type: Number, default: 0 },
    is_published: { type: Boolean, default: false },

    // Stages system
    stages: [{
      stage_index:  { type: Number, required: true },
      exercise_ids: [{ type: Schema.Types.ObjectId, ref: 'Exercise' }],
      stage_type:   { type: String, default: 'mixed' },
    }],
    stages_count: { type: Number, default: 0, min: 0, max: 5 },
  },
  { timestamps: true }
);

LessonSchema.index({ unit_id: 1, order: 1 });
LessonSchema.index({ trail_id: 1 });

export const LessonModel = mongoose.model<ILesson>('Lesson', LessonSchema);
