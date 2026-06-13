import { api } from './api';

export interface MissionTemplate {
  _id: string;
  id: string;
  title: string;
  description: string;
  icon_emoji: string;
  cycle: 'daily' | 'weekly';
  trigger: string;
  target: number;
  difficulty: 'easy' | 'medium' | 'hard';
  pf_reward: number;
  mana_reward: number;
  verse_reference?: string;
  verse_text?: string;
  is_active: boolean;
  is_premium: boolean;
  weight: number;
  sort_order: number;
}

export interface MissionStats {
  total: number;
  active: number;
  daily: number;
  weekly: number;
  premium: number;
  easy: number;
  medium: number;
  hard: number;
}

export const missionsService = {
  list: (params?: Record<string, unknown>) =>
    api.get('/admin/missions/templates', { params }),

  stats: () =>
    api.get('/admin/missions/templates/stats'),

  getById: (id: string) =>
    api.get(`/admin/missions/templates/${id}`),

  create: (data: Partial<MissionTemplate>) =>
    api.post('/admin/missions/templates', data),

  update: (id: string, data: Partial<MissionTemplate>) =>
    api.put(`/admin/missions/templates/${id}`, data),

  delete: (id: string) =>
    api.delete(`/admin/missions/templates/${id}`),

  seed: () =>
    api.post('/admin/missions/templates/seed'),
};
