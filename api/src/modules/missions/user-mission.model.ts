import mongoose, { Document, Schema } from 'mongoose';
import { MissionCycle, MissionTrigger, MissionDifficulty } from './mission-template.model';

export interface IUserMission extends Document {
  user_id: mongoose.Types.ObjectId;
  template_id: mongoose.Types.ObjectId;
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
  progress: number;
  status: 'active' | 'completed' | 'expired';
  cycle_start: Date;
  cycle_end: Date;
  completed_at?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const UserMissionSchema = new Schema<IUserMission>(
  {
    user_id: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    template_id: { type: Schema.Types.ObjectId, ref: 'MissionTemplate', required: true },
    title: { type: String, required: true },
    description: { type: String, required: true },
    icon_emoji: { type: String, default: '🎯' },
    cycle: { type: String, enum: ['daily', 'weekly'], required: true },
    trigger: { type: String, required: true },
    target: { type: Number, required: true },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'], default: 'easy' },
    pf_reward: { type: Number, default: 10 },
    mana_reward: { type: Number, default: 5 },
    verse_reference: String,
    verse_text: String,
    progress: { type: Number, default: 0 },
    status: { type: String, enum: ['active', 'completed', 'expired'], default: 'active' },
    cycle_start: { type: Date, required: true },
    cycle_end: { type: Date, required: true },
    completed_at: Date,
  },
  { timestamps: true },
);

UserMissionSchema.index({ user_id: 1, status: 1, cycle_end: 1 });
UserMissionSchema.index({ user_id: 1, cycle: 1, cycle_start: 1 });
UserMissionSchema.index({ cycle_end: 1, status: 1 });

export const UserMission = mongoose.model<IUserMission>('UserMission', UserMissionSchema);
