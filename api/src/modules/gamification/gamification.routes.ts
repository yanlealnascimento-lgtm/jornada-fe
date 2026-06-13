import { Router } from 'express';
import { GamificationController } from './gamification.controller';
import { authMiddleware } from '../../shared/middleware/auth.middleware';

const router = Router();
const controller = new GamificationController();

router.use(authMiddleware);

router.get('/leagues/me', controller.getLeagueDetails);
router.get('/leagues/leaderboard/global', controller.getGlobalLeaderboard);
router.get('/achievements', controller.getAchievements);
router.post('/streak/freeze', controller.buyStreakFreeze);

export default router;
