import mongoose, { Schema, Document } from 'mongoose';
import { CompanyType, CompanyPlan } from '../../shared/types';

export interface ICompany extends Document {
  cnpj?: string;
  name: string;
  slug: string;
  type: CompanyType;
  
  address: {
    street?: string;
    number?: string;
    city: string;
    state?: string;
    zipcode?: string;
    country: string;
  };
  
  responsible: {
    name: string;
    email: string;
    phone?: string;
    role?: string;
  };
  
  logo_url?: string;
  primary_color?: string;
  custom_name?: string;
  
  plan: CompanyPlan;
  plan_expires_at?: Date;
  members_limit: number;
  
  stats: {
    total_members: number;
    active_today: number;
    active_this_week: number;
    average_streak: number;
    updated_at: Date;
  };
  
  allow_public_join: boolean;
  invite_code: string;
  custom_trail_ids: mongoose.Types.ObjectId[];
  
  is_active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const CompanySchema = new Schema<ICompany>(
  {
    cnpj: { type: String, sparse: true, unique: true },
    name: { type: String, required: true },
    slug: { type: String, required: true, unique: true },
    type: { type: String, enum: ['church', 'school', 'ngo', 'company', 'other'], required: true },
    
    address: {
      street: { type: String },
      number: { type: String },
      city: { type: String, required: true },
      state: { type: String },
      zipcode: { type: String },
      country: { type: String, default: 'BR' },
    },
    
    responsible: {
      name: { type: String, required: true },
      email: { type: String, required: true },
      phone: { type: String },
      role: { type: String },
    },
    
    logo_url: { type: String },
    primary_color: { type: String, default: '#4A90E2' },
    custom_name: { type: String },
    
    plan: { type: String, enum: ['free', 'basic', 'professional', 'enterprise'], default: 'free' },
    plan_expires_at: { type: Date },
    members_limit: { type: Number, default: 30 },
    
    stats: {
      total_members: { type: Number, default: 0 },
      active_today: { type: Number, default: 0 },
      active_this_week: { type: Number, default: 0 },
      average_streak: { type: Number, default: 0 },
      updated_at: { type: Date, default: Date.now },
    },
    
    allow_public_join: { type: Boolean, default: true },
    invite_code: { type: String, required: true, unique: true },
    custom_trail_ids: [{ type: Schema.Types.ObjectId, ref: 'Trail' }],
    
    is_active: { type: Boolean, default: true },
  },
  { timestamps: true }
);

CompanySchema.index({ slug: 1 });
CompanySchema.index({ invite_code: 1 });

export const CompanyModel = mongoose.model<ICompany>('Company', CompanySchema);
