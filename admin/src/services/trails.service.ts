import { api } from './api';

export interface Trail {
  _id:             string;
  id:              string;
  title:           string;
  slug:            string;
  description:     string;
  thumbnail_url?:  string;
  character_id?:   { _id: string; name: string; sprite_url?: string; color_hex?: string } | string | null;
  order:           number;
  is_core:         boolean;
  denomination?:   string;
  unlock_level:    number;
  estimated_hours: number;
  is_premium:      boolean;
  is_published:    boolean;
  total_units:     number;
  total_lessons:   number;
  createdAt:       string;
  updatedAt:       string;
}

export interface TrailStats {
  total:           number;
  published:       number;
  draft:           number;
  free:            number;
  premium:         number;
  core:            number;
  denomination:    number;
  by_denomination: Record<string, number>;
}

export interface ListTrailsParams {
  is_published?:  boolean;
  is_core?:       boolean;
  is_premium?:    boolean;
  denomination?:  string;
  search?:        string;
  page?:          number;
  limit?:         number;
}

export const trailsService = {
  list:    (params?: ListTrailsParams) =>
    api.get('/admin/trails', { params }),

  stats:   () =>
    api.get('/admin/trails/stats'),

  getById: (id: string) =>
    api.get(`/admin/trails/${id}`),

  create:  (data: Partial<Trail>) =>
    api.post('/admin/trails', data),

  update:  (id: string, data: Partial<Trail>) =>
    api.put(`/admin/trails/${id}`, data),

  delete:  (id: string) =>
    api.delete(`/admin/trails/${id}`),

  reorder: (items: { id: string; order: number }[]) =>
    api.post('/admin/trails/reorder', { items }),

  seed:    () =>
    api.post('/admin/trails/seed'),
};
