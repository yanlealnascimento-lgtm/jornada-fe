import mongoose, { Document, Schema } from 'mongoose';

export type StudyDifficulty = 'beginner' | 'intermediate' | 'advanced';
export type StudyCategory =
  | 'personagens' | 'doutrinas' | 'vida-crista'
  | 'profecias'   | 'livros'    | 'devocionais' | 'sazonais';

export interface IBibleStudyLesson {
  order:         number;
  title:         string;
  verse_ref:     string;
  verse_text:    string;
  verse_version: string;
  dialogue_intro:       string;
  dialogue_character:   string;
  dialogue_reaction:    string;
  dialogue_application: string;
  dialogue_dove_close:  string;
  quiz_mc: {
    question: string;
    options:  string[];
    correct:  number;
  };
  quiz_fill: {
    verse_with_blank: string;
    answer:           string;
    hint:             string;
  };
  quiz_order: {
    words:   string[];
    correct: string[];
  };
  ai_explanation_cache?: string;
  ai_cached_at?:         Date;
  pf_reward:   number;
  mana_reward: number;
}

export interface IBibleStudy extends Document {
  title:         string;
  slug:          string;
  description:   string;
  thumbnail_url?: string;
  category:      StudyCategory;
  difficulty:    StudyDifficulty;
  character_id?: mongoose.Types.ObjectId;
  lessons:       IBibleStudyLesson[];
  total_lessons: number;
  is_premium:   boolean;
  is_published: boolean;
  is_featured:  boolean;
  series_slug?:  string;
  series_order?: number;
  total_completions: number;
  tags:  string[];
  order: number;
  createdAt: Date;
  updatedAt: Date;
}

const LessonSchema = new Schema<IBibleStudyLesson>({
  order:                { type: Number, required: true },
  title:                { type: String, required: true },
  verse_ref:            { type: String, required: true },
  verse_text:           { type: String, required: true },
  verse_version:        { type: String, default: 'NVI' },
  dialogue_intro:       { type: String, required: true },
  dialogue_character:   { type: String, required: true },
  dialogue_reaction:    { type: String, required: true },
  dialogue_application: { type: String, required: true },
  dialogue_dove_close:  { type: String, required: true },
  quiz_mc: {
    question: String,
    options:  [String],
    correct:  Number,
  },
  quiz_fill: {
    verse_with_blank: String,
    answer:           String,
    hint:             String,
  },
  quiz_order: {
    words:   [String],
    correct: [String],
  },
  ai_explanation_cache: String,
  ai_cached_at:         Date,
  pf_reward:   { type: Number, default: 25 },
  mana_reward: { type: Number, default: 8 },
}, { _id: false });

const BibleStudySchema = new Schema<IBibleStudy>({
  title:         { type: String, required: true },
  slug:          { type: String, required: true, unique: true },
  description:   { type: String, required: true },
  thumbnail_url: String,
  category:      { type: String, required: true },
  difficulty:    { type: String, enum: ['beginner', 'intermediate', 'advanced'], default: 'beginner' },
  character_id:  { type: Schema.Types.ObjectId, ref: 'Character' },
  lessons:       [LessonSchema],
  total_lessons: { type: Number, default: 0 },
  is_premium:    { type: Boolean, default: true },
  is_published:  { type: Boolean, default: false },
  is_featured:   { type: Boolean, default: false },
  series_slug:   String,
  series_order:  Number,
  total_completions: { type: Number, default: 0 },
  tags:  [String],
  order: { type: Number, default: 0 },
}, { timestamps: true });

BibleStudySchema.index({ slug: 1 }, { unique: true });
BibleStudySchema.index({ category: 1, is_published: 1 });
BibleStudySchema.index({ is_premium: 1, is_published: 1 });
BibleStudySchema.index({ is_featured: 1, is_published: 1 });

BibleStudySchema.pre('save', function (next) {
  this.total_lessons = this.lessons.length;
  next();
});

export const BibleStudyModel = mongoose.model<IBibleStudy>('BibleStudy', BibleStudySchema);
