import { api } from './api';

export interface Achievement {
  _id: string;
  id: string;
  key: string;
  name: string;
  description: string;
  verse_reference?: string;
  verse_text?: string;
  icon_emoji: string;
  icon_url?: string;
  trigger: { type: string; value: number };
  rarity: string;
  pf_reward: number;
  mana_reward: number;
  is_active: boolean;
  sort_order: number;
}

export interface AchievementStats {
  total: number;
  active: number;
  inactive: number;
  common: number;
  rare: number;
  epic: number;
}

export const achievementsService = {
  list: (params?: Record<string, unknown>) =>
    api.get('/admin/achievements', { params }),

  stats: () =>
    api.get('/admin/achievements/stats'),

  getById: (id: string) =>
    api.get(`/admin/achievements/${id}`),

  create: (data: Partial<Achievement>) =>
    api.post('/admin/achievements', data),

  update: (id: string, data: Partial<Achievement>) =>
    api.put(`/admin/achievements/${id}`, data),

  delete: (id: string) =>
    api.delete(`/admin/achievements/${id}`),

  seed: () =>
    api.post('/admin/achievements/seed'),
};
