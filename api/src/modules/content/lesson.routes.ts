import { Router } from 'express';
import { lessonController } from './lesson.controller';

const adminRouter = Router();
adminRouter.get('/', lessonController.list.bind(lessonController));
adminRouter.get('/:id', lessonController.getById.bind(lessonController));
adminRouter.post('/', lessonController.create.bind(lessonController));
adminRouter.put('/:id/stages', lessonController.updateStages.bind(lessonController));
adminRouter.put('/:id', lessonController.update.bind(lessonController));
adminRouter.delete('/:id', lessonController.delete.bind(lessonController));

export const lessonAdminRoutes = adminRouter;
