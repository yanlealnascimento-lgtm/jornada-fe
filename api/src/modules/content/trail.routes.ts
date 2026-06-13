import { Router } from 'express';
import { trailController } from './trail.controller';
// import { authMiddleware, adminMiddleware } from '../../shared/middleware/auth.middleware';

const router = Router();

// ROTAS PUBLICAS (app Flutter consome)
// router.use(authMiddleware); // [ATIVAR antes do lançamento]
router.get('/',           trailController.listPublished.bind(trailController));
router.get('/slug/:slug', trailController.getBySlug.bind(trailController));
router.get('/:id',        trailController.getById.bind(trailController));
router.get('/:id/units',  trailController.getUnitsWithLessons.bind(trailController));

export const trailPublicRoutes = router;

// ROTAS ADMIN
const adminRouter = Router();
// adminRouter.use(adminMiddleware); // [ATIVAR antes do lançamento]

adminRouter.get('/',           trailController.listAdmin.bind(trailController));
adminRouter.get('/stats',      trailController.getStats.bind(trailController));
adminRouter.get('/slug/:slug', trailController.getBySlug.bind(trailController));
adminRouter.get('/:id',        trailController.getById.bind(trailController));
adminRouter.post('/seed',      trailController.seed.bind(trailController));
adminRouter.post('/reorder',   trailController.reorder.bind(trailController));
adminRouter.post('/',          trailController.create.bind(trailController));
adminRouter.put('/:id',        trailController.update.bind(trailController));
adminRouter.delete('/:id',     trailController.delete.bind(trailController));

export const trailAdminRoutes = adminRouter;
