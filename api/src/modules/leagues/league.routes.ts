import { Router } from 'express';
import { leagueController } from './league.controller';
// import { authMiddleware, adminMiddleware } from '../../shared/middleware/auth.middleware';

const router = Router();

// ROTAS PUBLICAS (app Flutter consome)
// router.use(authMiddleware); // [ATIVAR antes do lancamento]
router.get('/me',    leagueController.getUserLeague.bind(leagueController));
router.post('/join', leagueController.joinLeague.bind(leagueController));
router.post('/pf',   leagueController.addPF.bind(leagueController));
router.post('/xp',   leagueController.addPF.bind(leagueController)); // backward compat

export const leaguePublicRoutes = router;

// ROTAS ADMIN
const adminRouter = Router();
// adminRouter.use(adminMiddleware); // [ATIVAR antes do lancamento]

adminRouter.get('/stats',              leagueController.getAdminStats.bind(leagueController));
adminRouter.post('/seed',              leagueController.seed.bind(leagueController));
adminRouter.post('/seed-mock-users',   leagueController.seed.bind(leagueController));
adminRouter.post('/process-weekly',    leagueController.processWeekly.bind(leagueController));

export const leagueAdminRoutes = adminRouter;
