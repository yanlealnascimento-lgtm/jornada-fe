import { Router } from 'express';
import { missionController } from './mission.controller';

// ROTAS PÚBLICAS (app Flutter consome)
const router = Router();
router.get('/', missionController.getUserMissions.bind(missionController));
router.get('/history', missionController.getHistory.bind(missionController));
router.get('/stats', missionController.getUserStats.bind(missionController));
router.post('/event', missionController.processEvent.bind(missionController));

export const missionPublicRoutes = router;

// ROTAS ADMIN
const adminRouter = Router();
adminRouter.get('/templates', missionController.listTemplates.bind(missionController));
adminRouter.get('/templates/stats', missionController.getStats.bind(missionController));
adminRouter.get('/templates/:id', missionController.getTemplateById.bind(missionController));
adminRouter.post('/templates/seed', missionController.seed.bind(missionController));
adminRouter.post('/templates', missionController.createTemplate.bind(missionController));
adminRouter.put('/templates/:id', missionController.updateTemplate.bind(missionController));
adminRouter.delete('/templates/:id', missionController.deleteTemplate.bind(missionController));

export const missionAdminRoutes = adminRouter;
