import { z } from 'zod';

export const createUserSchema = z.object({
  email: z.string().email('E-mail inválido'),
  password: z.string().min(6, 'A senha deve ter pelo menos 6 caracteres'),
  name: z.string().min(2, 'O nome deve ter pelo menos 2 caracteres'),
  role: z.enum(['user', 'admin', 'company_admin']).optional(),
  company_id: z.string().optional(),
});

export const updateUserSchema = z.object({
  name: z.string().min(2, 'O nome deve ter pelo menos 2 caracteres').optional(),
  username: z.string().min(2, 'O usuário deve ter pelo menos 2 caracteres').optional(),
  phone: z.string().optional(),
  role: z.enum(['user', 'admin', 'company_admin']).optional(),
  avatar_url: z.string().url('Avatar URL inválida').optional(),
  denomination: z.string().optional(),
  daily_goal_minutes: z.number().min(1).optional(),
  timezone: z.string().optional(),
  notification_hour: z.number().min(0).max(23).optional(),
});

export const getUserParamsSchema = z.object({
  id: z.string().regex(/^[0-9a-fA-F]{24}$/, 'ID de usuário inválido'),
});
