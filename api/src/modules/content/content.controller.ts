import { Request, Response, NextFunction } from 'express';
import { ContentService } from './content.service';
import { sendSuccess, sendError } from '../../shared/utils/response.util';

export class ContentController {
  private service: ContentService;

  constructor() {
    this.service = new ContentService();
  }

  getTrails = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user?.userId as string;
      const trails = await this.service.getTrails(userId);
      return sendSuccess(res, trails, 'Trilhas recuperadas.');
    } catch (error) {
      next(error);
    }
  };

  getTrailDetail = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user?.userId as string;
      const trail = await this.service.getTrailDetail(req.params.trailId, userId);
      if (!trail) return sendError(res, 'Trilha não encontrada.', 'NOT_FOUND', 404);
      return sendSuccess(res, trail, 'Detalhe da trilha.');
    } catch (error) {
      next(error);
    }
  };

  getLessonDetail = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const lesson = await this.service.getLesson(req.params.lessonId);
      if (!lesson) return sendError(res, 'Lição não encontrada.', 'NOT_FOUND', 404);
      return sendSuccess(res, lesson, 'Lição recuperada para jogo.');
    } catch (error) {
      next(error);
    }
  };

  completeLesson = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user?.userId as string;
      const result = await this.service.completeLesson(req.params.lessonId, userId, req.body);
      return sendSuccess(res, result, 'Resultado processado com sucesso.');
    } catch (error) {
      next(error);
    }
  };
}
