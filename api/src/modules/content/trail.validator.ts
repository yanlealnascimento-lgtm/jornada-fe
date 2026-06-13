import { z } from 'zod';

export const generateSlug = (title: string): string =>
  title
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim();

export const createTrailSchema = z.object({
  title:           z.string().min(3, 'Título deve ter no mínimo 3 caracteres').max(100),
  slug:            z.string().optional(),
  description:     z.string().min(10, 'Descrição deve ter no mínimo 10 caracteres').max(500),
  thumbnail_url:   z.string().url('URL inválida').optional().or(z.literal('')),
  character_id:    z.string().optional(),
  order:           z.number().int().min(0).optional(),
  is_core:         z.boolean().default(true),
  denomination:    z.string().optional(),
  unlock_level:    z.number().int().min(1).max(100).default(1),
  estimated_hours: z.number().min(0.5).max(200).default(1),
  is_premium:      z.boolean().default(false),
  is_published:    z.boolean().default(false),
  company_id:      z.string().optional(),
});

export const updateTrailSchema = createTrailSchema.partial();

export const reorderTrailsSchema = z.object({
  items: z.array(z.object({
    id:    z.string(),
    order: z.number().int().min(0),
  })),
});

export type CreateTrailInput  = z.infer<typeof createTrailSchema>;
export type UpdateTrailInput  = z.infer<typeof updateTrailSchema>;
export type ReorderTrailInput = z.infer<typeof reorderTrailsSchema>;
