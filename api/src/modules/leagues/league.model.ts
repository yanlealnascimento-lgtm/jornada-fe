import mongoose, { Schema, Document } from 'mongoose';
import { LeagueTier, LEAGUE_TIERS_ORDERED } from '../../shared/types';

// ── League (group/lobby) ──────────────────────────────────────────────

export interface ILeague extends Document {
  tier: LeagueTier;
  week_key: string;
  group_id: number;
  max_members: number;
  is_active: boolean;
  starts_at: Date;
  ends_at: Date;
  processed: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const LeagueSchema = new Schema<ILeague>(
  {
    tier: {
      type: String,
      enum: LEAGUE_TIERS_ORDERED,
      required: true,
    },
    week_key: { type: String, required: true },
    group_id: { type: Number, required: true, default: 0 },
    max_members: { type: Number, default: 30 },
    is_active: { type: Boolean, default: true },
    starts_at: { type: Date, required: true },
    ends_at: { type: Date, required: true },
    processed: { type: Boolean, default: false },
  },
  { timestamps: true },
);

LeagueSchema.index({ week_key: 1, tier: 1, group_id: 1 }, { unique: true });
LeagueSchema.index({ is_active: 1 });

export const LeagueModel = mongoose.model<ILeague>('League', LeagueSchema);

// ── LeagueMember (one row per user per week) ──────────────────────────

export interface ILeagueMember extends Document {
  league_id: mongoose.Types.ObjectId;
  user_id: string;
  display_name: string;
  avatar_seed: string;
  faith_points: number;
  is_mock: boolean;
  week_key: string;
  tier: LeagueTier;
  createdAt: Date;
  updatedAt: Date;
}

const LeagueMemberSchema = new Schema<ILeagueMember>(
  {
    league_id: {
      type: Schema.Types.ObjectId,
      ref: 'League',
      required: true,
    },
    user_id: { type: String, required: true },
    display_name: { type: String, required: true },
    avatar_seed: { type: String, default: '' },
    faith_points: { type: Number, default: 0 },
    is_mock: { type: Boolean, default: false },
    week_key: { type: String, required: true },
    tier: {
      type: String,
      enum: LEAGUE_TIERS_ORDERED,
      required: true,
    },
  },
  { timestamps: true },
);

// Leaderboard query: all members of a tier+week sorted by faith_points desc
LeagueMemberSchema.index(
  { week_key: 1, tier: 1, faith_points: -1 },
);

// Fast lookup: find a specific user's entry for a given week
LeagueMemberSchema.index(
  { user_id: 1, week_key: 1 },
  { unique: true },
);

export const LeagueMemberModel = mongoose.model<ILeagueMember>(
  'LeagueMember',
  LeagueMemberSchema,
);
