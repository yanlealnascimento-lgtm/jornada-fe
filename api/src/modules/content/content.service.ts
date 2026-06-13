import { ContentRepository } from './content.repository';
import { AnswerCheckerService } from './answer-checker.service';
import { UserProgressModel } from '../users/user-progress.model'; // Para salvamento direto ou migrar p/ repo
import mongoose from 'mongoose';

export class ContentService {
  private repository: ContentRepository;
  private answerChecker: AnswerCheckerService;

  constructor() {
    this.repository = new ContentRepository();
    this.answerChecker = new AnswerCheckerService();
  }

  async getTrails(userId: string) {
    return await this.repository.getTrailsWithUserProgress(userId);
  }

  async getTrailDetail(trailId: string, userId: string) {
    return await this.repository.getTrailDetail(trailId, userId);
  }

  async getLesson(lessonId: string) {
    const data = await this.repository.getLessonWithExercises(lessonId);
    if (!data) return null;

    // TODO: Embaralhar exercícios (Fisher-Yates) para dinâmica e ocultar respostas corretas nos schemas pro mobile!
    data.exercises = data.exercises.map((ex: any) => {
        if (ex.type === 'fill_blank') delete ex.correct_answer;
        if (ex.type === 'sort_words' && ex.words_to_sort) {
            ex.words_to_sort = ex.words_to_sort.sort(() => Math.random() - 0.5);
        }
        if (ex.type === 'pair_match' && ex.pairs) {
            // Em uma implementação full mix, criaríamos um array visual de esquerdas e direitas avulsos cru
        }
        return ex;
    });

    return data;
  }

  async completeLesson(lessonId: string, userId: string, payload: any) {
    // 1. Validar e analisar cada answer vs exercise original
    const fullLesson = await this.repository.getLessonWithExercises(lessonId);
    if (!fullLesson) throw new Error('Lesson not found');
    
    let mistakes = 0;
    
    payload.exercises_results.forEach((userResult: any) => {
        const exercise = fullLesson.exercises.find((e: any) => e._id.toString() === userResult.exercise_id);
        if (!exercise) return;
        
        const isCorrect = this.answerChecker.checkAnswer(exercise, userResult.user_answer);
        if (!isCorrect) mistakes++;
    });

    // 2. Cálculo score e pf
    const totalEx = fullLesson.exercises.length || 1;
    const corrects = totalEx - mistakes;
    const score = Math.round((corrects / totalEx) * 100);
    const perfect = mistakes === 0;
    
    const pf_earned = fullLesson.pf_reward + (perfect ? fullLesson.pf_perfect_bonus : 0);
    
    // 3. Salvar progresso no Mongoose
    await UserProgressModel.findOneAndUpdate({
        user_id: new mongoose.Types.ObjectId(userId),
        lesson_id: new mongoose.Types.ObjectId(lessonId),
    }, {
        trail_id: fullLesson.trail_id,
        unit_id: fullLesson.unit_id,
        status: 'completed',
        score,
        pf_earned,
        mistakes_count: mistakes,
        perfect,
        time_spent_seconds: payload.total_time_seconds || 0,
        completed_at: new Date()
    }, { upsert: true, new: true });
    
    return {
        lesson_completed: true,
        score,
        pf_earned,
        mistakes,
        perfect,
        level_up: false, // Integração com GamificationModule próxima rodada
        new_level: 0,
        streak: { current: 0, maintained: true },
        achievements_unlocked: []
    };
  }
}
