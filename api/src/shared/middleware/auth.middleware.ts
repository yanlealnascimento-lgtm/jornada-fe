import { Request, Response, NextFunction } from 'express';
import jwt, { JwtPayload } from 'jsonwebtoken';
import { sendError } from '../utils/response.util';

export const authMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    // Para facilitar testes do admin atual que usa X-User-Id
    const devUserId = req.headers['x-user-id'] as string;
    if (devUserId) {
      req.user = { 
        userId: devUserId, 
        email: devUserId === 'dev-admin-001' ? 'admin@journeyfaith.com' : 'dev@journeyfaith.com', 
        role: devUserId === 'dev-admin-001' ? 'admin' : 'user'
      };
      return next();
    }
    return sendError(res, 'Sessão expirada. Faça login novamente.', 'UNAUTHORIZED', 401);
  }

  try {
    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;
    
    req.user = { 
      userId: decoded.userId, 
      email: decoded.email, 
      role: decoded.role,
      company_id: decoded.company_id 
    };
    
    next();
  } catch (err) {
    return sendError(res, 'Sessão inválida ou expirada.', 'UNAUTHORIZED', 401);
  }
};

export const adminMiddleware = (req: Request, res: Response, next: NextFunction) => {
  authMiddleware(req, res, () => {
    if (req.user?.role !== 'admin') {
      return sendError(res, 'Acesso restrito a administradores.', 'FORBIDDEN', 403);
    }
    next();
  });
};
