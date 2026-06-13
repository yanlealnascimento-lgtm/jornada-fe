import { Router } from 'express';
import { AdminController } from './admin.controller';
import { adminMiddleware } from '../../shared/middleware/auth.middleware';

const router = Router();
const controller = new AdminController();

// Todas as rotas administrativas passam pelo middleware que injeta admin no user
// Removido router.use(adminMiddleware) global para não colidir com rotas públicas do B2B em app.ts

// --- Trilhas (Trails) --- movidas para trail.routes.ts

// --- Personagens (Characters) --- movidos para character.routes.ts

// --- Conquistas (Achievements) --- movidas para achievement.routes.ts

// --- Ligas (Leagues) --- movidas para league.routes.ts
// router.get('/leagues', adminMiddleware, controller.getLeagues);
// router.post('/leagues', adminMiddleware, controller.createLeague);
// router.post('/leagues/process-weekly', adminMiddleware, controller.processWeekly);

// --- Instituições (Companies) ---
router.get('/companies', adminMiddleware, controller.getCompanies);
router.post('/companies', adminMiddleware, controller.createCompany);
router.put('/companies/:id', adminMiddleware, controller.updateCompany);
router.patch('/companies/:id/status', adminMiddleware, controller.toggleCompanyStatus);

// --- Usuários (Users) ---
router.get('/users', adminMiddleware, controller.getUsers);

// --- Exercícios (Exercises) ---
router.get('/exercises', adminMiddleware, controller.getExercises);
router.get('/exercises/:id', adminMiddleware, controller.getExercise);
router.post('/exercises', adminMiddleware, controller.createExercise);
router.put('/exercises/:id', adminMiddleware, controller.updateExercise);
router.delete('/exercises/:id', adminMiddleware, controller.deleteExercise);
router.post('/exercises/seed', adminMiddleware, controller.seedExercises);

// Seed
router.post('/seed-all', adminMiddleware, controller.seedAll);

export default router;
