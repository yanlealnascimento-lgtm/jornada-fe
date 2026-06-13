import { TrailModel, ITrail } from './trail.model';
import { UnitModel, IUnit } from './unit.model';
import { LessonModel, ILesson } from './lesson.model';
import { ExerciseModel, IExercise } from './exercise.model';
import { UserProgressModel } from '../users/user-progress.model';
import mongoose from 'mongoose';

export class ContentRepository {
  
  async getTrailsWithUserProgress(userId: string): Promise<any[]> {
    const trails = await TrailModel.find({ is_published: true }).sort({ order: 1 }).lean();
    
    // Para simplificar no repositório cru, mapearemos os progresso e colaremos neles.
    const progress = await UserProgressModel.find({ 
        user_id: new mongoose.Types.ObjectId(userId), 
        status: 'completed' 
    }).lean();
    
    return trails.map(trail => {
       const completedCount = progress.filter(p => p.trail_id.toString() === trail._id.toString()).length;
       return {
           ...trail,
           user_completed_lessons: completedCount
       };
    });
  }

  async getTrailDetail(trailId: string, userId: string): Promise<any> {
    const trail = await TrailModel.findById(trailId).lean();
    if (!trail) return null;

    const units = await UnitModel.find({ trail_id: trailId, is_published: true }).sort({ order: 1 }).lean();
    const unitIds = units.map(u => u._id);
    
    const lessons = await LessonModel.find({ unit_id: { $in: unitIds }, is_published: true }).sort({ unit_id: 1, order: 1 }).lean();
    const progresses = await UserProgressModel.find({ user_id: new mongoose.Types.ObjectId(userId), trail_id: trailId }).lean();

    const formattedUnits = units.map(unit => {
        const unitLessons = lessons.filter(l => l.unit_id.toString() === unit._id.toString());
        
        return {
            ...unit,
            lessons: unitLessons.map(lesson => {
                const prog = progresses.find(p => p.lesson_id.toString() === lesson._id.toString());
                return {
                    ...lesson,
                    status: prog ? prog.status : 'not_started',
                    score: prog?.score || 0,
                    perfect: prog?.perfect || false
                };
            })
        };
    });

    return {
        ...trail,
        units: formattedUnits
    };
  }

  async getLessonWithExercises(lessonId: string): Promise<any> {
    const lesson = await LessonModel.findById(lessonId).lean();
    if (!lesson) return null;

    const exercises = await ExerciseModel.find({ lesson_id: lessonId }).sort({ order: 1 }).lean();

    return {
        ...lesson,
        exercises
    };
  }
}
