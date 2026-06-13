import { Router, Request, Response, NextFunction } from 'express';
import { UserController } from './user.controller';
import { UserProgressController } from './user-progress.controller';
import { UserModel } from './user.model';
import { validate } from '../../shared/middleware/validate.middleware';
import { createUserSchema, updateUserSchema, getUserParamsSchema } from './user.validator';
import { sendSuccess, sendError } from '../../shared/utils/response.util';
import { isToday, isYesterday } from '../../shared/utils/date.util';

const router = Router();
const controller = new UserController();
const progressController = new UserProgressController();

router.post('/', validate(createUserSchema, 'body'), controller.create);
router.get('/', controller.getAll);
router.get('/:id', validate(getUserParamsSchema, 'params'), controller.getById);
router.put('/:id', validate(getUserParamsSchema, 'params'), validate(updateUserSchema, 'body'), controller.update);
router.delete('/:id', validate(getUserParamsSchema, 'params'), controller.delete);

// Progresso do usuário
router.get('/:id/progress', progressController.getProgress);
router.post('/:id/exercises/:exerciseId/complete', progressController.completeExercise);

// PATCH /api/v1/users/me/streak — Sync streak from mobile app
router.patch('/me/streak', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.body.user_id || req.headers['x-user-id'];
    if (!userId) return sendError(res, 'user_id obrigatório', 'VALIDATION_ERROR', 400);

    const user = await UserModel.findById(userId);
    if (!user) return sendError(res, 'Usuário não encontrado', 'NOT_FOUND', 404);

    const lastActivity = user.streak_last_activity;
    let newStreak = user.streak_current;

    if (lastActivity && isToday(lastActivity)) {
      // Already counted today
      return sendSuccess(res, {
        streak_current: user.streak_current,
        streak_longest: user.streak_longest,
      });
    }

    if (lastActivity && isYesterday(lastActivity)) {
      newStreak++;
    } else if (lastActivity) {
      // Missed days — check freeze
      const now = new Date();
      const lastDay = new Date(lastActivity);
      lastDay.setHours(0, 0, 0, 0);
      now.setHours(0, 0, 0, 0);
      const daysMissed = Math.floor((now.getTime() - lastDay.getTime()) / 86400000) - 1;

      if (daysMissed === 1 && user.streak_freeze_count >= 1) {
        // Escudo cobre exatamente 1 dia perdido — consumir e incrementar por hoje
        user.streak_freeze_count -= 1;
        newStreak++;
      } else {
        // Perdeu 2+ dias OU sem escudo — ofensiva zerada, hoje começa em 1
        newStreak = 1;
      }
    } else {
      // First ever activity
      newStreak = 1;
    }

    user.streak_current = newStreak;
    user.streak_last_activity = new Date();
    if (newStreak > user.streak_longest) {
      user.streak_longest = newStreak;
    }
    await user.save();

    return sendSuccess(res, {
      streak_current: user.streak_current,
      streak_longest: user.streak_longest,
      streak_freeze_count: user.streak_freeze_count,
    });
  } catch (error) { next(error); }
});

// PATCH /api/v1/users/me/energy — Sync energy from mobile app
router.patch('/me/energy', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.body.user_id || req.headers['x-user-id'];
    if (!userId) return sendError(res, 'user_id obrigatório', 'VALIDATION_ERROR', 400);

    const { energy } = req.body;
    if (energy == null) return sendError(res, 'energy obrigatório', 'VALIDATION_ERROR', 400);

    const clamped = Math.max(0, Math.min(20, Number(energy)));
    await UserModel.findByIdAndUpdate(userId, {
      energy: clamped,
      energy_last_consumed: new Date(),
    });

    return sendSuccess(res, { energy: clamped });
  } catch (error) { next(error); }
});

export default router;
