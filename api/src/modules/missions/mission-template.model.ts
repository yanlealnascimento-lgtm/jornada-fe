import mongoose, { Document, Schema } from 'mongoose';

export type MissionCycle = 'daily' | 'weekly';
export type MissionTrigger =
  | 'lesson_count'
  | 'perfect_lesson'
  | 'streak_maintain'
  | 'pf_earn'
  | 'trail_progress'
  | 'study_complete'
  | 'league_xp'
  | 'invite_friend'
  | 'review_lesson';

export type MissionDifficulty = 'easy' | 'medium' | 'hard';

export interface IMissionTemplate extends Document {
  title: string;
  description: string;
  icon_emoji: string;
  cycle: MissionCycle;
  trigger: MissionTrigger;
  target: number;
  difficulty: MissionDifficulty;
  pf_reward: number;
  mana_reward: number;
  verse_reference?: string;
  verse_text?: string;
  is_active: boolean;
  is_premium: boolean;
  weight: number;
  sort_order: number;
  createdAt: Date;
  updatedAt: Date;
}

const MissionTemplateSchema = new Schema<IMissionTemplate>(
  {
    title: { type: String, required: true },
    description: { type: String, required: true },
    icon_emoji: { type: String, default: '🎯' },
    cycle: { type: String, enum: ['daily', 'weekly'], required: true },
    trigger: {
      type: String,
      enum: [
        'lesson_count',
        'perfect_lesson',
        'streak_maintain',
        'pf_earn',
        'trail_progress',
        'study_complete',
        'league_xp',
        'invite_friend',
        'review_lesson',
      ],
      required: true,
    },
    target: { type: Number, required: true, min: 1 },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'], default: 'easy' },
    pf_reward: { type: Number, default: 10 },
    mana_reward: { type: Number, default: 5 },
    verse_reference: String,
    verse_text: String,
    is_active: { type: Boolean, default: true },
    is_premium: { type: Boolean, default: false },
    weight: { type: Number, default: 5, min: 1, max: 10 },
    sort_order: { type: Number, default: 0 },
  },
  { timestamps: true },
);

MissionTemplateSchema.index({ cycle: 1, is_active: 1 });
MissionTemplateSchema.index({ trigger: 1 });

export const MissionTemplate = mongoose.model<IMissionTemplate>(
  'MissionTemplate',
  MissionTemplateSchema,
);
