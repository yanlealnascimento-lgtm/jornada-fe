import mongoose, { Schema, Document } from 'mongoose';

export interface IAchievement extends Document {
  key: string;
  name: string;
  description: string;
  verse_reference?: string;
  verse_text?: string;
  icon_emoji: string;
  icon_url: string;

  trigger: {
    type: 'lesson_count' | 'streak_days' | 'trail_complete' | 'league_rank' | 'invite_count' | 'pf_total' | 'level' | 'perfect_lesson' | 'pf_earn' | 'trail_progress' | 'study_complete' | 'league_xp' | 'review_lesson' | 'streak_maintain';
    value: number;
  };

  rarity: 'common' | 'rare' | 'epic';
  pf_reward: number;
  mana_reward: number;

  // Fields merged from missions
  cycle?: 'one_time' | 'daily' | 'weekly';
  difficulty?: 'easy' | 'medium' | 'hard';
  is_premium: boolean;

  is_active: boolean;
  sort_order: number;

  createdAt: Date;
  updatedAt: Date;
}

const AchievementSchema = new Schema<IAchievement>(
  {
    key: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    description: { type: String, required: true },
    verse_reference: { type: String },
    verse_text: { type: String },
    icon_emoji: { type: String, default: '🏆' },
    icon_url: { type: String },

    trigger: {
      type: { type: String, enum: ['lesson_count', 'streak_days', 'trail_complete', 'league_rank', 'invite_count', 'pf_total', 'level', 'perfect_lesson', 'pf_earn', 'trail_progress', 'study_complete', 'league_xp', 'review_lesson', 'streak_maintain'], required: true },
      value: { type: Number, required: true },
    },

    rarity: { type: String, enum: ['common', 'rare', 'epic'], default: 'common' },
    pf_reward: { type: Number, default: 0 },
    mana_reward: { type: Number, default: 0 },

    cycle: { type: String, enum: ['one_time', 'daily', 'weekly'], default: 'one_time' },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'] },
    is_premium: { type: Boolean, default: false },

    is_active: { type: Boolean, default: true },
    sort_order: { type: Number, default: 0 },
  },
  { timestamps: true }
);

AchievementSchema.index({ is_active: 1, sort_order: 1 });
AchievementSchema.index({ key: 1 }, { unique: true });
AchievementSchema.index({ 'trigger.type': 1 });

export const AchievementModel = mongoose.model<IAchievement>('Achievement', AchievementSchema);
