import { api } from './api';

export type CharacterRarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'special';

export interface CharacterDialogue {
  type: string;
  text: string;
}

export interface Character {
  _id:               string;
  id:                string;
  name:              string;
  title:             string;
  biblical_reference:string;
  biblical_story:    string;
  sprite_url:        string;
  lottie_idle_url?:  string;
  lottie_happy_url?: string;
  lottie_sad_url?:   string;
  color_hex:         string;
  rarity:            CharacterRarity;
  trail_id?:         { _id: string; title: string; slug: string } | string | null;
  unlock_condition:  { type: string; value?: string | number };
  dialogues:         CharacterDialogue[];
  is_sacred:         boolean;
  is_active:         boolean;
  sort_order:        number;
  createdAt:         string;
}

export interface CharacterStats {
  total: number; active: number; inactive: number;
  common: number; uncommon: number; rare: number; epic: number; special: number; sacred: number;
}

export const charactersService = {
  list:         (params?: Record<string, unknown>) =>
    api.get('/admin/characters', { params }),

  stats:        () =>
    api.get('/admin/characters/stats'),

  getById:      (id: string) =>
    api.get(`/admin/characters/${id}`),

  create:       (data: Partial<Character>) =>
    api.post('/admin/characters', data),

  update:       (id: string, data: Partial<Character>) =>
    api.put(`/admin/characters/${id}`, data),

  delete:       (id: string) =>
    api.delete(`/admin/characters/${id}`),

  toggleActive: (id: string) =>
    api.patch(`/admin/characters/${id}/toggle-active`),

  seed:         () =>
    api.post('/admin/characters/seed'),
};
