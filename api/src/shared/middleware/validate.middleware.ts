import { Request, Response, NextFunction } from 'express';
import { ZodSchema } from 'zod';

export const validate = (schema: ZodSchema, source: 'body' | 'params' | 'query' = 'body') =>
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      if (source === 'body') {
        req.body = await schema.parseAsync(req.body);
      } else if (source === 'params') {
        req.params = await schema.parseAsync(req.params);
      } else if (source === 'query') {
        req.query = await schema.parseAsync(req.query);
      }
      next();
    } catch (error) {
      next(error);
    }
  };
