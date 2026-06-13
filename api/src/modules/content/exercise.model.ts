import mongoose, { Schema, Document } from 'mongoose';
import { ExerciseType } from '../../shared/types';

export interface IExercise extends Document {
  // Vínculo com lição (opcional para exercícios standalone do admin)
  lesson_id?: mongoose.Types.ObjectId;

  // Identificação
  title?: string;
  description?: string;
  level: number;
  order: number;
  is_active: boolean;
  is_premium: boolean;

  // Tipo
  type: ExerciseType | 'emoji_guess' | 'audio_recite';

  // Conteúdo
  question: string;
  instruction?: string;
  context_image_url?: string;
  verse_reference?: string;
  emoji_hint?: string;

  // Opções simples (array de strings) — usado pelo app Flutter
  options_text?: string[];

  // Opções complexas (com id, text, is_correct) — usado pelos exercícios linked a lessons
  options?: {
    id: string;
    text: string;
    is_correct: boolean;
  }[];

  correct_answer?: string;
  word_bank?: string[];
  words_to_sort?: string[];
  correct_order?: string[];
  pairs?: { left: string; right: string }[];

  explanation: string;
  character_reaction?: 'happy' | 'sad' | 'surprised' | 'neutral';
  difficulty: 'easy' | 'medium' | 'hard';
  pf_reward: number;

  createdAt: Date;
  updatedAt: Date;
}

const ExerciseSchema = new Schema<IExercise>(
  {
    lesson_id: { type: Schema.Types.ObjectId, ref: 'Lesson', required: false },
    title: { type: String },
    description: { type: String },
    level: { type: Number, default: 1 },
    order: { type: Number, default: 0 },
    is_active: { type: Boolean, default: true },
    is_premium: { type: Boolean, default: false },

    type: {
      type: String,
      enum: ['multiple_choice', 'fill_blank', 'sort_words', 'pair_match', 'true_false', 'emoji_guess', 'audio_recite'],
      required: true,
    },

    question: { type: String, required: true },
    instruction: { type: String },
    context_image_url: { type: String },
    verse_reference: { type: String },
    emoji_hint: { type: String },

    options_text: [{ type: String }],

    options: [{
      id: { type: String },
      text: { type: String },
      is_correct: { type: Boolean },
    }],

    correct_answer: { type: String },
    word_bank: [{ type: String }],
    words_to_sort: [{ type: String }],
    correct_order: [{ type: String }],
    pairs: [{ left: { type: String }, right: { type: String } }],

    explanation: { type: String, required: true },
    character_reaction: { type: String, enum: ['happy', 'sad', 'surprised', 'neutral'], default: 'neutral' },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'], default: 'easy' },
    pf_reward: { type: Number, default: 10 },
  },
  { timestamps: true }
);

ExerciseSchema.index({ lesson_id: 1, order: 1 });
ExerciseSchema.index({ level: 1, type: 1 });
ExerciseSchema.index({ is_active: 1 });

export const ExerciseModel = mongoose.model<IExercise>('Exercise', ExerciseSchema);
