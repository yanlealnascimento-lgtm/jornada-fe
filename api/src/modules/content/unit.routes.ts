import { Router } from 'express';
import { unitController } from './unit.controller';

const adminRouter = Router();
adminRouter.get('/', unitController.list.bind(unitController));
adminRouter.post('/', unitController.create.bind(unitController));
adminRouter.put('/:id', unitController.update.bind(unitController));
adminRouter.delete('/:id', unitController.delete.bind(unitController));

export const unitAdminRoutes = adminRouter;
