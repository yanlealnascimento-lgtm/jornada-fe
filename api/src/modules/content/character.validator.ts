import { z } from 'zod';

const dialogueSchema = z.object({
  type: z.enum(['greeting','lesson_start','correct','wrong',
                'lesson_complete','streak_warning','streak_broken','level_up']),
  text: z.string().min(1, 'Texto do diálogo não pode ser vazio').max(300),
});

const unlockConditionSchema = z.object({
  type:  z.enum(['default','trail_complete','level','streak','achievement']).default('default'),
  value: z.union([z.string(), z.number()]).optional(),
});

export const createCharacterSchema = z.object({
  name:               z.string().min(2, 'Nome deve ter no mínimo 2 caracteres').max(50),
  title:              z.string().min(2).max(80),
  biblical_reference: z.string().min(3).max(150),
  biblical_story:     z.string().min(10, 'História deve ter no mínimo 10 caracteres').max(1000),
  sprite_url:         z.string().url('URL do sprite inválida'),
  lottie_idle_url:    z.string().url().optional().or(z.literal('')),
  lottie_happy_url:   z.string().url().optional().or(z.literal('')),
  lottie_sad_url:     z.string().url().optional().or(z.literal('')),
  color_hex:          z.string().regex(/^#[0-9A-Fa-f]{6}$/, 'Cor deve estar no formato #RRGGBB').default('#4A90E2'),
  rarity:             z.enum(['common','uncommon','rare','epic','special']).default('common'),
  trail_id:           z.string().optional(),
  unlock_condition:   unlockConditionSchema.default({ type: 'default' }),
  dialogues:          z.array(dialogueSchema).default([]),
  is_sacred:          z.boolean().default(false),
  is_active:          z.boolean().default(true),
  sort_order:         z.number().int().min(0).optional(),
});

export const updateCharacterSchema = createCharacterSchema.partial();

export type CreateCharacterInput = z.infer<typeof createCharacterSchema>;
export type UpdateCharacterInput = z.infer<typeof updateCharacterSchema>;
