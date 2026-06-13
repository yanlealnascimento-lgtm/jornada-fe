import { api } from './api';

export interface LeagueStats {
  active_leagues: number;
  total_members: number;
  by_tier: Record<string, { leagues: number; members: number }>;
  current_week: string;
}

export const leaguesService = {
  stats: () =>
    api.get('/admin/leagues/stats'),

  seed: () =>
    api.post('/admin/leagues/seed'),

  processWeekly: () =>
    api.post('/admin/leagues/process-weekly'),
};
