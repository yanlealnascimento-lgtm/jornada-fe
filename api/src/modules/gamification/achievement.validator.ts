import { z } from 'zod';

export const createAchievementSchema = z.object({
  key: z
    .string()
    .min(1, 'Key é obrigatório')
    .regex(/^[a-z][a-z0-9_]*$/, 'Key deve ser snake_case (ex: first_lesson)'),
  name: z.string().min(2, 'Nome deve ter no mínimo 2 caracteres').max(100),
  description: z.string().min(5, 'Descrição deve ter no mínimo 5 caracteres').max(500),
  verse_reference: z.string().optional(),
  verse_text: z.string().optional(),
  icon_emoji: z.string().default('🏆'),
  icon_url: z.string().url('URL inválida').optional().or(z.literal('')),
  trigger: z.object({
    type: z.enum([
      'lesson_count',
      'streak_days',
      'trail_complete',
      'league_rank',
      'invite_count',
      'pf_total',
      'level',
      'perfect_lesson',
    ]),
    value: z.number().int().min(1),
  }),
  rarity: z.enum(['common', 'rare', 'epic']).default('common'),
  pf_reward: z.number().int().min(0).default(0),
  mana_reward: z.number().int().min(0).default(0),
  is_active: z.boolean().default(true),
  sort_order: z.number().int().min(0).default(0),
});

export const updateAchievementSchema = createAchievementSchema.partial();

export type CreateAchievementInput = z.infer<typeof createAchievementSchema>;
export type UpdateAchievementInput = z.infer<typeof updateAchievementSchema>;
