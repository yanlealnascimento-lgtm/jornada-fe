import { Router, Request, Response, NextFunction } from 'express';
import { ExerciseModel } from './exercise.model';
import { sendSuccess, sendError } from '../../shared/utils/response.util';

const router = Router();

// GET /api/v1/exercises — listar exercícios ativos (consumido pelo app Flutter)
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { level, type, limit = '50' } = req.query;
    const filter: Record<string, any> = { is_active: true };
    if (level) filter.level = Number(level);
    if (type) filter.type = type;

    const items = await ExerciseModel.find(filter)
      .sort({ level: 1, order: 1 })
      .limit(Number(limit))
      .lean();

    return sendSuccess(res, items, 'Exercícios recuperados.');
  } catch (error) { next(error); }
});

// GET /api/v1/exercises/lesson/:lessonId — Exercícios de uma lição específica
router.get('/lesson/:lessonId', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const exercises = await ExerciseModel.find({
      lesson_id: req.params.lessonId,
      is_active: true,
    })
      .sort({ order: 1 })
      .lean();

    return sendSuccess(res, exercises.map((e: any) => ({ ...e, id: e._id })));
  } catch (error) { next(error); }
});

// GET /api/v1/exercises/:id
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const item = await ExerciseModel.findById(req.params.id).lean();
    if (!item) return sendError(res, 'Exercício não encontrado.', 'NOT_FOUND', 404);
    return sendSuccess(res, item, 'Exercício encontrado.');
  } catch (error) { next(error); }
});

// ─── Admin Routes ──────────────────────────────────────────────────────────

const adminRouter = Router();

// GET /api/v1/admin/exercises?lesson_id=X or ?unlinked=true
adminRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { lesson_id, unlinked, search } = req.query;
    const filter: Record<string, any> = {};
    if (lesson_id) filter.lesson_id = lesson_id;
    if (unlinked === 'true') filter.$or = [{ lesson_id: null }, { lesson_id: { $exists: false } }];
    if (search) filter.question = { $regex: search, $options: 'i' };

    const items = await ExerciseModel.find(filter).sort({ order: 1, createdAt: -1 }).lean();
    return sendSuccess(res, items.map((e: any) => ({ ...e, id: e._id })));
  } catch (error) { next(error); }
});

// POST /api/v1/admin/exercises
adminRouter.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const exercise = await ExerciseModel.create(req.body);
    // Update lesson total_exercises
    if (exercise.lesson_id) {
      const { LessonModel } = await import('./lesson.model');
      const count = await ExerciseModel.countDocuments({ lesson_id: exercise.lesson_id, is_active: true });
      await LessonModel.findByIdAndUpdate(exercise.lesson_id, { $set: { total_exercises: count } });
    }
    return sendSuccess(res, { ...exercise.toObject(), id: exercise._id }, 'Exercício criado', 201);
  } catch (error) { next(error); }
});

// PUT /api/v1/admin/exercises/:id
adminRouter.put('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const exercise = await ExerciseModel.findByIdAndUpdate(req.params.id, { $set: req.body }, { new: true });
    if (!exercise) return sendError(res, 'Exercício não encontrado', 'NOT_FOUND', 404);
    // Update lesson total_exercises
    if (exercise.lesson_id) {
      const { LessonModel } = await import('./lesson.model');
      const count = await ExerciseModel.countDocuments({ lesson_id: exercise.lesson_id, is_active: true });
      await LessonModel.findByIdAndUpdate(exercise.lesson_id, { $set: { total_exercises: count } });
    }
    return sendSuccess(res, { ...exercise.toObject(), id: exercise._id }, 'Exercício atualizado');
  } catch (error) { next(error); }
});

// DELETE /api/v1/admin/exercises/:id
adminRouter.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const exercise = await ExerciseModel.findByIdAndDelete(req.params.id);
    if (!exercise) return sendError(res, 'Exercício não encontrado', 'NOT_FOUND', 404);
    if (exercise.lesson_id) {
      const { LessonModel } = await import('./lesson.model');
      const count = await ExerciseModel.countDocuments({ lesson_id: exercise.lesson_id, is_active: true });
      await LessonModel.findByIdAndUpdate(exercise.lesson_id, { $set: { total_exercises: count } });
    }
    return sendSuccess(res, null, 'Exercício removido');
  } catch (error) { next(error); }
});

// POST /api/v1/admin/exercises/link — Vincular exercicio a licao
adminRouter.post('/link', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { exercise_id, lesson_id } = req.body;
    if (!exercise_id || !lesson_id) return sendError(res, 'exercise_id e lesson_id são obrigatórios', 'VALIDATION_ERROR', 400);
    const exercise = await ExerciseModel.findByIdAndUpdate(exercise_id, { $set: { lesson_id } }, { new: true });
    if (!exercise) return sendError(res, 'Exercício não encontrado', 'NOT_FOUND', 404);
    // Update lesson total_exercises
    const { LessonModel } = await import('./lesson.model');
    const count = await ExerciseModel.countDocuments({ lesson_id, is_active: true });
    await LessonModel.findByIdAndUpdate(lesson_id, { $set: { total_exercises: count } });
    return sendSuccess(res, { ...exercise.toObject(), id: exercise._id }, 'Exercício vinculado');
  } catch (error) { next(error); }
});

// POST /api/v1/admin/exercises/unlink — Desvincular exercicio
adminRouter.post('/unlink', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { exercise_id } = req.body;
    const exercise = await ExerciseModel.findById(exercise_id);
    if (!exercise) return sendError(res, 'Exercício não encontrado', 'NOT_FOUND', 404);
    const oldLessonId = exercise.lesson_id;
    exercise.lesson_id = undefined as any;
    await exercise.save();
    if (oldLessonId) {
      const { LessonModel } = await import('./lesson.model');
      const count = await ExerciseModel.countDocuments({ lesson_id: oldLessonId, is_active: true });
      await LessonModel.findByIdAndUpdate(oldLessonId, { $set: { total_exercises: count } });
    }
    return sendSuccess(res, null, 'Exercício desvinculado');
  } catch (error) { next(error); }
});

export { adminRouter as exerciseAdminRoutes };
export default router;
