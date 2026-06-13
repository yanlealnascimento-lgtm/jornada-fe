import { Request, Response, NextFunction } from 'express';
import { CompanyService } from './company.service';
import { sendSuccess, sendError } from '../../shared/utils/response.util';
import { UserModel } from '../users/user.model';

export class CompanyController {
  private service = new CompanyService();

  create = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const company = await this.service.createCompany(req.body);
      return sendSuccess(res, company, 'Comunidade criada com sucesso.', 201);
    } catch (error) {
      next(error);
    }
  };

  getStats = async (req: Request, res: Response, next: NextFunction) => {
    try {
       const stats = await this.service.getCompanyStats(req.params.companyId);
       return sendSuccess(res, stats, 'Dashboard de stats comunitários retornado.');
    } catch (error) {
       next(error);
    }
  };

  join = async (req: Request, res: Response, next: NextFunction) => {
      try {
          const userId = req.user?.userId as string;
          const { invite_code } = req.body;
          const company = await this.service.joinByInviteCode(invite_code, userId);
          return sendSuccess(res, company, 'Bem-vindo à comunidade!');
      } catch (err: any) {
          return sendError(res, err.message, 'JOIN_ERROR', 400);
      }
  }

  getMembers = async (req: Request, res: Response, next: NextFunction) => {
      try {
         const users = await UserModel.find({ company_id: req.params.companyId })
                                      .select('name pf_total streak_current last_seen_at avatar_url');
         return sendSuccess(res, users, 'Membros retornados com sucesso');
      } catch (err) {
          next(err);
      }
  }
}
