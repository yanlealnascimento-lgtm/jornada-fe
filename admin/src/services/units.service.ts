import { api } from './api';

export interface Unit {
  _id: string;
  id: string;
  trail_id: string;
  title: string;
  description: string;
  order: number;
  icon_name: string;
  color_hex: string;
  unlock_condition: { type: string; value?: string | number };
  is_published: boolean;
  lesson_count: number;
}

export interface Lesson {
  _id: string;
  id: string;
  unit_id: string;
  trail_id: string;
  title: string;
  subtitle: string;
  order: number;
  pf_reward: number;
  pf_perfect_bonus: number;
  estimated_minutes: number;
  lesson_type: string;
  total_exercises: number;
  is_published: boolean;
}

export const unitsService = {
  list: (trailId: string) =>
    api.get('/admin/units', { params: { trail_id: trailId } }),

  create: (data: Partial<Unit>) =>
    api.post('/admin/units', data),

  update: (id: string, data: Partial<Unit>) =>
    api.put(`/admin/units/${id}`, data),

  delete: (id: string) =>
    api.delete(`/admin/units/${id}`),
};

export const lessonsService = {
  list: (unitId: string) =>
    api.get('/admin/lessons', { params: { unit_id: unitId } }),

  create: (data: Partial<Lesson>) =>
    api.post('/admin/lessons', data),

  update: (id: string, data: Partial<Lesson>) =>
    api.put(`/admin/lessons/${id}`, data),

  delete: (id: string) =>
    api.delete(`/admin/lessons/${id}`),
};
