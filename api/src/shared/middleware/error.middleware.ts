import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { sendError } from '../utils/response.util';
import { logger } from '../utils/logger';

export const errorMiddleware = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  logger.error('Error in request:', err);

  if (err instanceof ZodError) {
    const errorDetails = err.errors.map(e => `${e.path.join('.')}: ${e.message}`).join(', ');
    sendError(res, `Validação falhou: ${errorDetails}`, 'UNPROCESSABLE_ENTITY', 422);
    return;
  }

  if (err.name === 'CastError' && err.kind === 'ObjectId') {
    sendError(res, 'ID inválido fornecido.', 'INVALID_ID', 400);
    return;
  }

  if (err.name === 'ValidationError') {
    sendError(res, err.message || 'Erro de validação no banco de dados.', 'DB_VALIDATION_ERROR', 400);
    return;
  }

  if (err.name === 'MongoServerError' && err.code === 11000) {
    sendError(res, 'Um registro com estes dados únicos já existe.', 'DUPLICATE_KEY_ERROR', 409);
    return;
  }

  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    sendError(res, 'Token inválido ou expirado.', 'UNAUTHORIZED', 401);
    return;
  }

  const statusCode = err.statusCode || 500;
  const message = process.env.NODE_ENV === 'production' && statusCode === 500 
    ? 'Erro interno do servidor' 
    : err.message || 'Erro interno do servidor';
  
  sendError(res, message, err.code || 'INTERNAL_ERROR', statusCode);
};
