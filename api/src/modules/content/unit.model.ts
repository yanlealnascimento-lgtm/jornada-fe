import mongoose, { Schema, Document } from 'mongoose';

export interface IUnit extends Document {
  trail_id: mongoose.Types.ObjectId;
  title: string;
  description?: string;
  order: number;
  
  icon_name: string;
  color_hex: string;
  
  unlock_condition: {
    type: 'previous_unit' | 'level' | 'free';
    value?: number | string; // ID of previous unit or min level
  };
  
  is_published: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const UnitSchema = new Schema<IUnit>(
  {
    trail_id: { type: Schema.Types.ObjectId, ref: 'Trail', required: true },
    title: { type: String, required: true },
    description: { type: String },
    order: { type: Number, required: true },
    
    icon_name: { type: String, required: true },
    color_hex: { type: String, required: true },
    
    unlock_condition: {
      type: { type: String, enum: ['previous_unit', 'level', 'free'], default: 'free' },
      value: { type: Schema.Types.Mixed },
    },
    
    is_published: { type: Boolean, default: false },
  },
  { timestamps: true }
);

UnitSchema.index({ trail_id: 1, order: 1 });

export const UnitModel = mongoose.model<IUnit>('Unit', UnitSchema);
