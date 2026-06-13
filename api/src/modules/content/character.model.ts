import mongoose, { Schema, Document } from 'mongoose';
import { CharacterRarity } from '../../shared/types';

export interface ICharacter extends Document {
  name: string;
  title: string;
  biblical_reference: string;
  biblical_story: string;
  
  sprite_url: string;
  lottie_idle_url?: string;
  lottie_happy_url?: string;
  lottie_sad_url?: string;
  color_hex: string;
  
  rarity: CharacterRarity;
  trail_id?: mongoose.Types.ObjectId;
  
  unlock_condition: {
    type: 'trail_complete' | 'level' | 'streak' | 'achievement' | 'default';
    value?: string | number;
  };
  
  dialogues: {
    type: 'greeting' | 'lesson_start' | 'correct' | 'wrong' | 'lesson_complete' | 'streak_warning' | 'streak_broken' | 'level_up';
    text: string;
  }[];
  
  is_sacred: boolean;
  is_active: boolean;
  sort_order: number;
  
  createdAt: Date;
  updatedAt: Date;
}

const CharacterSchema = new Schema<ICharacter>(
  {
    name: { type: String, required: true },
    title: { type: String, required: true },
    biblical_reference: { type: String, required: true },
    biblical_story: { type: String, required: true },
    
    sprite_url: { type: String, required: true },
    lottie_idle_url: { type: String },
    lottie_happy_url: { type: String },
    lottie_sad_url: { type: String },
    color_hex: { type: String, required: true },
    
    rarity: { type: String, enum: ['common', 'uncommon', 'rare', 'epic', 'special'], required: true },
    trail_id: { type: Schema.Types.ObjectId, ref: 'Trail' },
    
    unlock_condition: {
      type: { type: String, enum: ['trail_complete', 'level', 'streak', 'achievement', 'default'], default: 'default' },
      value: { type: Schema.Types.Mixed },
    },
    
    dialogues: [{
      type: { type: String, enum: ['greeting', 'lesson_start', 'correct', 'wrong', 'lesson_complete', 'streak_warning', 'streak_broken', 'level_up'] },
      text: { type: String },
    }],
    
    is_sacred: { type: Boolean, default: false },
    is_active: { type: Boolean, default: true },
    sort_order: { type: Number, default: 0 },
  },
  { timestamps: true }
);

CharacterSchema.index({ is_active: 1, sort_order: 1 });

export const CharacterModel = mongoose.model<ICharacter>('Character', CharacterSchema);
