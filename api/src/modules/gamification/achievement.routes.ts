import { Router } from 'express';
import { achievementController } from './achievement.controller';
// import { authMiddleware, adminMiddleware } from '../../shared/middleware/auth.middleware';

const router = Router();

// ROTAS PUBLICAS (app Flutter consome)
// router.use(authMiddleware); // [ATIVAR antes do lançamento]
router.get('/',            achievementController.listActive.bind(achievementController));
router.get('/user/:userId', achievementController.getUserAchievements.bind(achievementController));
router.get('/:id',         achievementController.getById.bind(achievementController));

export const achievementPublicRoutes = router;

// ROTAS ADMIN
const adminRouter = Router();
// adminRouter.use(adminMiddleware); // [ATIVAR antes do lançamento]

adminRouter.get('/',       achievementController.listAdmin.bind(achievementController));
adminRouter.get('/stats',  achievementController.getStats.bind(achievementController));
adminRouter.get('/:id',    achievementController.getById.bind(achievementController));
adminRouter.post('/seed',  achievementController.seed.bind(achievementController));
adminRouter.post('/',      achievementController.create.bind(achievementController));
adminRouter.put('/:id',    achievementController.update.bind(achievementController));
adminRouter.delete('/:id', achievementController.delete.bind(achievementController));

export const achievementAdminRoutes = adminRouter;
