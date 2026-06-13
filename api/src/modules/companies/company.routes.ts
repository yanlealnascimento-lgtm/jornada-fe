import { Router } from 'express';
import { CompanyController } from './company.controller';
import { CompanyB2BController } from './controllers/company-b2b.controller';
import { authMiddleware } from '../../shared/middleware/auth.middleware';

const router = Router();
const controller = new CompanyController();
const b2bController = new CompanyB2BController();

// Seed (Público de dev)
router.post('/b2b/seed', b2bController.seedB2BData);

// Criação isolada
router.post('/', controller.create);

router.use(authMiddleware);

// Entrada (App)
router.post('/join', controller.join);

// B2B Dashboard (Gestão)
router.get('/b2b/members', b2bController.getMembers);
router.get('/b2b/groups', b2bController.getGroups);
router.post('/b2b/groups', b2bController.createGroup);
router.put('/b2b/groups/:id', b2bController.updateGroup);
router.delete('/b2b/groups/:id', b2bController.deleteGroup);
router.get('/b2b/settings', b2bController.getSettings);

// Stats e Gerenciamento
router.get('/:companyId/stats', controller.getStats);
router.get('/:companyId/members', controller.getMembers);

export default router;

