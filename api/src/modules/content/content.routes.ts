import { Router } from 'express';
import { ContentController } from './content.controller';
import { authMiddleware } from '../../shared/middleware/auth.middleware';

const router = Router();
const controller = new ContentController();

router.use(authMiddleware); // Inject dummy auth behavior for X-User-Id extraction MVP.

router.get('/trails', controller.getTrails);
router.get('/trails/:trailId', controller.getTrailDetail);
router.get('/lessons/:lessonId', controller.getLessonDetail);
router.post('/lessons/:lessonId/complete', controller.completeLesson);

export default router;
