import { Request, Response, NextFunction } from 'express';
import { UserService } from './user.service';
import { sendSuccess, sendError } from '../../shared/utils/response.util';

export class UserController {
  private service: UserService;

  constructor() {
    this.service = new UserService();
  }

  create = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const user = await this.service.createUser(req.body);
      return sendSuccess(res, user, 'Usuário criado com sucesso.', 201);
    } catch (error) {
      next(error);
    }
  };

  getAll = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const users = await this.service.getAllUsers();
      return sendSuccess(res, users, 'Usuários recuperados com sucesso.');
    } catch (error) {
      next(error);
    }
  };

  getById = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = req.params;
      const user = await this.service.getUserById(id);
      
      if (!user) {
        return sendError(res, 'Usuário não encontrado.', 'NOT_FOUND', 404);
      }
      
      // Remover password hash
      user.passwordHash = '';
      return sendSuccess(res, user, 'Usuário encontrado.');
    } catch (error) {
      next(error);
    }
  };

  update = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = req.params;
      const updatedUser = await this.service.updateUser(id, req.body);
      
      if (!updatedUser) {
        return sendError(res, 'Usuário não encontrado.', 'NOT_FOUND', 404);
      }
      
      return sendSuccess(res, updatedUser, 'Usuário atualizado com sucesso.');
    } catch (error) {
      next(error);
    }
  };

  delete = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = req.params;
      const success = await this.service.deleteUser(id);
      
      if (!success) {
        return sendError(res, 'Usuário não encontrado.', 'NOT_FOUND', 404);
      }
      
      return sendSuccess(res, null, 'Usuário deletado com sucesso.');
    } catch (error) {
      next(error);
    }
  };
}
