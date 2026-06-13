import mongoose, { Schema, Document } from 'mongoose';
import { UserPlan, LeagueTier } from '../../shared/types';

export interface IUser extends Document {
  name: string;
  username: string;
  email: string;
  phone?: string;
  passwordHash: string;
  avatar_url?: string;
  
  // Plano
  plan: UserPlan;
  plan_expires_at?: Date;
  
  // Gamificação
  pf_total: number;
  pf_weekly: number;
  level: number;
  pf_to_next_level: number;
  energy: number;
  energy_last_consumed: Date;
  manas: number;
  
  // Streak
  streak_current: number;
  streak_longest: number;
  streak_last_activity: Date;
  streak_freeze_count: number;
  
  // Liga
  league_id?: mongoose.Types.ObjectId;
  league_tier: LeagueTier;
  
  // Perfil
  denomination?: string;
  daily_goal_minutes: number;
  timezone: string;
  
  // Push
  fcm_token?: string;
  notifications_enabled: boolean;
  notification_hour: number;
  
  // Institutional
  company_id?: mongoose.Types.ObjectId;
  
  // Status
  is_active: boolean;
  last_seen_at: Date;
  role: 'user' | 'admin' | 'company_admin';
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>(
  {
    name: { type: String, required: true, trim: true },
    username: { type: String, required: true, unique: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    phone: { type: String, trim: true },
    passwordHash: { type: String, required: true, select: false },
    avatar_url: { type: String },
    
    plan: { type: String, enum: ['free', 'plus_monthly', 'plus_annual'], default: 'free' },
    plan_expires_at: { type: Date },
    
    pf_total: { type: Number, default: 0 },
    pf_weekly: { type: Number, default: 0 },
    level: { type: Number, default: 1 },
    pf_to_next_level: { type: Number, default: 1000 },
    energy: { type: Number, default: 20, max: 20 },
    energy_last_consumed: { type: Date },
    manas: { type: Number, default: 200 },
    
    streak_current: { type: Number, default: 0 },
    streak_longest: { type: Number, default: 0 },
    streak_last_activity: { type: Date, default: Date.now },
    streak_freeze_count: { type: Number, default: 0 },
    
    league_id: { type: Schema.Types.ObjectId, ref: 'League' },
    league_tier: { type: String, enum: ['ruben', 'simeao', 'levi', 'juda', 'da', 'naftali', 'gad', 'aser', 'issacar', 'zebulom', 'efraim', 'manasses'], default: 'ruben' },
    
    denomination: { type: String },
    daily_goal_minutes: { type: Number, default: 10 },
    timezone: { type: String, default: 'America/Sao_Paulo' },
    
    fcm_token: { type: String },
    notifications_enabled: { type: Boolean, default: true },
    notification_hour: { type: Number, default: 20 },
    
    company_id: { type: Schema.Types.ObjectId, ref: 'Company' },
    role: { type: String, enum: ['user', 'admin', 'company_admin'], default: 'user' },
    
    is_active: { type: Boolean, default: true },
    last_seen_at: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

UserSchema.index({ email: 1 });
UserSchema.index({ username: 1 });
UserSchema.index({ company_id: 1 });
UserSchema.index({ league_id: 1 });
UserSchema.index({ streak_last_activity: 1 });

export const UserModel = mongoose.model<IUser>('User', UserSchema);
