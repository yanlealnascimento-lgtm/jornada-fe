import { Router } from 'express';
import { characterController } from './character.controller';
// import { authMiddleware, adminMiddleware } from '../../shared/middleware/auth.middleware';

// ROTAS PUBLICAS (app Flutter)
const router = Router();
// router.use(authMiddleware); // [ATIVAR antes do lançamento]

router.get('/',    characterController.listActive.bind(characterController));
router.get('/:id', characterController.getById.bind(characterController));

export const characterPublicRoutes = router;

// ROTAS ADMIN
const adminRouter = Router();
// adminRouter.use(adminMiddleware); // [ATIVAR antes do lançamento]

adminRouter.get('/',                    characterController.listAdmin.bind(characterController));
adminRouter.get('/stats',               characterController.getStats.bind(characterController));
adminRouter.get('/:id',                 characterController.getById.bind(characterController));
adminRouter.post('/seed',               characterController.seed.bind(characterController));
adminRouter.post('/',                   characterController.create.bind(characterController));
adminRouter.put('/:id',                 characterController.update.bind(characterController));
adminRouter.patch('/:id/toggle-active', characterController.toggleActive.bind(characterController));
adminRouter.delete('/:id',              characterController.delete.bind(characterController));

export const characterAdminRoutes = adminRouter;
