import mongoose, { Schema, Document } from 'mongoose';

export interface IStudyGroup extends Document {
  name: string;
  description: string;
  category: 'youth' | 'adults' | 'couples' | 'kids' | 'general';
  company_id: mongoose.Types.ObjectId;
  leader_id: mongoose.Types.ObjectId;
  member_ids: mongoose.Types.ObjectId[];
  icon_emoji: string;
  is_active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const StudyGroupSchema = new Schema<IStudyGroup>(
  {
    name: { type: String, required: true },
    description: { type: String, required: true },
    category: { type: String, enum: ['youth', 'adults', 'couples', 'kids', 'general'], default: 'general' },
    company_id: { type: Schema.Types.ObjectId, ref: 'Company', required: true },
    leader_id: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    member_ids: [{ type: Schema.Types.ObjectId, ref: 'User' }],
    icon_emoji: { type: String, default: '👥' },
    is_active: { type: Boolean, default: true },
  },
  { timestamps: true }
);

StudyGroupSchema.index({ company_id: 1 });
StudyGroupSchema.index({ leader_id: 1 });

export const StudyGroupModel = mongoose.model<IStudyGroup>('StudyGroup', StudyGroupSchema);
