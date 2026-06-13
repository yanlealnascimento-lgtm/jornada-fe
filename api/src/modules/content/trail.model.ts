import mongoose, { Schema, Document } from 'mongoose';

export interface ITrail extends Document {
  title: string;
  slug: string;
  description: string;
  thumbnail_url?: string;
  character_id: mongoose.Types.ObjectId;
  
  order: number;
  is_core: boolean;
  denomination?: string;
  unlock_level: number;
  
  total_units: number;
  total_lessons: number;
  estimated_hours: number;
  
  is_published: boolean;
  is_premium: boolean;
  
  company_id?: mongoose.Types.ObjectId;
  
  createdAt: Date;
  updatedAt: Date;
}

const TrailSchema = new Schema<ITrail>(
  {
    title: { type: String, required: true },
    slug: { type: String, required: true, unique: true },
    description: { type: String, required: true },
    thumbnail_url: { type: String },
    character_id: { type: Schema.Types.ObjectId, ref: 'Character' },
    
    order: { type: Number, required: true },
    is_core: { type: Boolean, default: true },
    denomination: { type: String },
    unlock_level: { type: Number, default: 1 },
    
    total_units: { type: Number, default: 0 },
    total_lessons: { type: Number, default: 0 },
    estimated_hours: { type: Number, default: 0 },
    
    is_published: { type: Boolean, default: false },
    is_premium: { type: Boolean, default: false },
    
    company_id: { type: Schema.Types.ObjectId, ref: 'Company' },
  },
  { timestamps: true }
);

TrailSchema.index({ slug: 1 });
TrailSchema.index({ company_id: 1 });
TrailSchema.index({ is_published: 1, order: 1 });

export const TrailModel = mongoose.model<ITrail>('Trail', TrailSchema);
