import { Router, Request, Response, NextFunction } from 'express';
import { LessonModel } from './lesson.model';
import { ExerciseModel } from './exercise.model';
import { UserLessonProgressModel } from './user-lesson-progress.model';
import { sendSuccess, sendError } from '../../shared/utils/response.util';
import { LeagueService } from '../leagues/league.service';
import { UserModel } from '../users/user.model';
import { getWeekKey } from '../../shared/utils/date.util';
import { achievementService } from '../gamification/achievement.service';

const router = Router();

// GET /api/v1/lessons/:lessonId/progress?user_id=xxx
router.get('/:lessonId/progress', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { user_id } = req.query;
    if (!user_id) {
      // No user — return default progress from lesson info
      const lesson = await LessonModel.findById(req.params.lessonId).lean();
      const stagesCount = lesson?.stages_count || lesson?.stages?.length || 1;
      return sendSuccess(res, {
        lesson_id: req.params.lessonId,
        stages_total: stagesCount,
        stages_completed: 0,
        current_stage: 0,
        status: 'not_started',
        pf_earned: 0,
        perfect: true,
      });
    }

    const progress = await UserLessonProgressModel.findOne({
      user_id, lesson_id: req.params.lessonId,
    }).lean();

    if (!progress) {
      // No progress yet — check lesson for stages info
      const lesson = await LessonModel.findById(req.params.lessonId).lean();
      const stagesCount = lesson?.stages_count || lesson?.stages?.length || 1;
      return sendSuccess(res, {
        lesson_id: req.params.lessonId,
        stages_total: stagesCount,
        stages_completed: 0,
        current_stage: 0,
        status: 'not_started',
        pf_earned: 0,
        perfect: true,
      });
    }

    return sendSuccess(res, progress);
  } catch (error) { next(error); }
});

// POST /api/v1/lessons/:lessonId/start
router.post('/:lessonId/start', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { user_id } = req.body;
    if (!user_id) return sendError(res, 'user_id obrigatório', 'VALIDATION_ERROR', 400);

    const lesson = await LessonModel.findById(req.params.lessonId).lean();
    if (!lesson) return sendError(res, 'Lição não encontrada', 'NOT_FOUND', 404);

    const stagesCount = lesson.stages_count || lesson.stages?.length || 1;

    // Find or create progress
    let progress = await UserLessonProgressModel.findOne({
      user_id, lesson_id: lesson._id,
    });

    if (!progress) {
      progress = await UserLessonProgressModel.create({
        user_id,
        lesson_id: lesson._id,
        unit_id: lesson.unit_id,
        trail_id: lesson.trail_id,
        stages_total: stagesCount,
        status: 'in_progress',
        started_at: new Date(),
        last_activity: new Date(),
      });
    } else if (progress.status === 'not_started') {
      progress.status = 'in_progress';
      progress.last_activity = new Date();
      await progress.save();
    }

    // Get exercises for the current stage
    let stageExercises: any[] = [];
    if (lesson.stages && lesson.stages.length > 0) {
      const currentStage = lesson.stages.find((s: any) => s.stage_index === progress!.current_stage);
      if (currentStage && currentStage.exercise_ids.length > 0) {
        stageExercises = await ExerciseModel.find({
          _id: { $in: currentStage.exercise_ids }, is_active: true,
        }).lean();
      }
    }

    // Fallback: if no stages configured, return all lesson exercises
    if (stageExercises.length === 0) {
      stageExercises = await ExerciseModel.find({
        lesson_id: lesson._id, is_active: true,
      }).lean();
    }

    return sendSuccess(res, {
      progress: { ...progress.toObject(), id: progress._id },
      stage_exercises: stageExercises.map((e: any) => ({ ...e, id: e._id })),
    });
  } catch (error) { next(error); }
});

// GET /api/v1/lessons/:lessonId/review-exercises
// Returns ~50% of all exercises from all stages, randomly picked
router.get('/:lessonId/review-exercises', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const lesson = await LessonModel.findById(req.params.lessonId).lean();
    if (!lesson) return sendError(res, 'Licao nao encontrada', 'NOT_FOUND', 404);

    const allExercises = await ExerciseModel.find({
      lesson_id: lesson._id, is_active: true,
    }).lean();

    if (allExercises.length === 0) {
      return sendSuccess(res, []);
    }

    // Shuffle and pick ~50% (minimum 5, max all)
    const shuffled = allExercises.sort(() => Math.random() - 0.5);
    const pickCount = Math.max(5, Math.ceil(allExercises.length / 2));
    const picked = shuffled.slice(0, Math.min(pickCount, shuffled.length));

    return sendSuccess(res, picked.map((e: any) => ({ ...e, id: e._id })));
  } catch (error) { next(error); }
});

// GET /api/v1/lessons/:lessonId/stages/:stageIndex/exercises
router.get('/:lessonId/stages/:stageIndex/exercises', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const lesson = await LessonModel.findById(req.params.lessonId).lean();
    if (!lesson) return sendError(res, 'Lição não encontrada', 'NOT_FOUND', 404);

    const stageIndex = parseInt(req.params.stageIndex, 10);
    const stage = lesson.stages?.find((s: any) => s.stage_index === stageIndex);

    let exercises: any[] = [];
    if (stage && stage.exercise_ids.length > 0) {
      exercises = await ExerciseModel.find({
        _id: { $in: stage.exercise_ids }, is_active: true,
      }).lean();
    } else {
      // Fallback: divide all exercises into stages evenly
      const allExercises = await ExerciseModel.find({
        lesson_id: lesson._id, is_active: true,
      }).sort({ order: 1 }).lean();

      const stagesCount = lesson.stages_count || 1;
      const perStage = Math.ceil(allExercises.length / stagesCount);
      const start = stageIndex * perStage;
      exercises = allExercises.slice(start, start + perStage);
    }

    return sendSuccess(res, exercises.map((e: any) => ({ ...e, id: e._id })));
  } catch (error) { next(error); }
});

// POST /api/v1/lessons/:lessonId/stages/:stageIndex/complete
router.post('/:lessonId/stages/:stageIndex/complete', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { user_id, pf_earned = 0, had_error = false } = req.body;
    if (!user_id) return sendError(res, 'user_id obrigatório', 'VALIDATION_ERROR', 400);

    const progress = await UserLessonProgressModel.findOne({
      user_id, lesson_id: req.params.lessonId,
    });
    if (!progress) return sendError(res, 'Progresso não encontrado. Chame /start primeiro.', 'NOT_FOUND', 404);

    const idx = parseInt(req.params.stageIndex, 10);

    // Validate stage order (skip for review mode or already completed lessons)
    if (idx !== progress.current_stage && progress.status !== 'completed') {
      console.warn(`[Stage] Ordem inesperada: esperada=${progress.current_stage}, recebida=${idx}, lesson=${req.params.lessonId}`);
      // Allow it anyway - don't block the user
    }

    // Update progress
    progress.stages_completed = idx + 1;
    progress.current_stage = idx + 1;
    progress.pf_earned += pf_earned;
    progress.last_activity = new Date();
    if (had_error) progress.perfect = false;

    // Check if lesson completed
    const lessonCompleted = progress.stages_completed >= progress.stages_total;
    if (lessonCompleted) {
      progress.status = 'completed';
      progress.completed_at = new Date();

      // Perfect bonus: +50% PF
      if (progress.perfect) {
        progress.pf_earned = Math.round(progress.pf_earned * 1.5);
      }
    } else {
      progress.status = 'in_progress';
    }

    await progress.save();

    // Persist PF to user document
    if (pf_earned > 0) {
      try {
        const pfResult = await UserModel.findByIdAndUpdate(user_id, {
          $inc: { pf_total: Number(pf_earned), pf_weekly: Number(pf_earned) },
        }, { new: true });
        console.log(`[PF] user=${user_id} +${pf_earned} => pf_total=${pfResult?.pf_total}`);
      } catch (err) {
        console.error('[PF] Failed to persist PF:', err);
      }
    }

    // Update level based on new pf_total
    try {
      const updated = await UserModel.findById(user_id).select('pf_total level streak_current').lean();
      if (updated) {
        const newLevel = Math.floor((updated.pf_total ?? 0) / 1000) + 1;
        if (newLevel !== updated.level) {
          await UserModel.findByIdAndUpdate(user_id, { level: newLevel, pf_to_next_level: 1000 });
        }
      }
    } catch (_) {}

    // Add PF to user's league (fire-and-forget)
    if (pf_earned > 0) {
      try {
        const leagueService = new LeagueService();
        const user = await UserModel.findById(user_id).select('league_tier').lean();
        const tier = (user as any)?.league_tier || 'ruben';
        const weekKey = getWeekKey();
        await leagueService.addPFToLeague(user_id, tier, weekKey, pf_earned);
      } catch (_) { /* silent — league PF is best-effort */ }
    }

    // Check and unlock achievements when lesson is completed
    if (lessonCompleted) {
      try {
        const [lessonsCount, userDoc] = await Promise.all([
          UserLessonProgressModel.countDocuments({ user_id, status: 'completed' }),
          UserModel.findById(user_id).select('pf_total streak_current level').lean(),
        ]);
        await achievementService.checkAfterEvent({
          userId: String(user_id),
          lessonsCompleted: lessonsCount,
          pfTotal: userDoc?.pf_total ?? 0,
          streakDays: userDoc?.streak_current ?? 0,
          level: userDoc?.level ?? 1,
          perfectLesson: progress.perfect,
        });
      } catch (_) { /* silent — achievement check is best-effort */ }
    }

    return sendSuccess(res, {
      stages_completed: progress.stages_completed,
      stages_total: progress.stages_total,
      current_stage: progress.current_stage,
      lesson_completed: lessonCompleted,
      pf_total: progress.pf_earned,
      perfect: progress.perfect,
    });
  } catch (error) { next(error); }
});

// GET /api/v1/lessons/progress/bulk?user_id=xxx&trail_id=yyy
// Returns all lesson progress for a user in a trail (for rendering the map)
router.get('/progress/bulk', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { user_id, trail_id } = req.query;
    if (!user_id) return sendSuccess(res, []); // No user = no progress

    const filter: Record<string, any> = { user_id };
    if (trail_id) filter.trail_id = trail_id;

    const progresses = await UserLessonProgressModel.find(filter).lean();
    return sendSuccess(res, progresses);
  } catch (error) { next(error); }
});

export const lessonProgressRoutes = router;
