export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
  pagination?: PaginationMeta;
}

export type ExerciseType = 
  | 'multiple_choice' 
  | 'fill_blank' 
  | 'sort_words' 
  | 'pair_match' 
  | 'true_false';

export type LeagueTier =
  | 'ruben'
  | 'simeao'
  | 'levi'
  | 'juda'
  | 'da'
  | 'naftali'
  | 'gad'
  | 'aser'
  | 'issacar'
  | 'zebulom'
  | 'efraim'
  | 'manasses';

export const LEAGUE_TIERS_ORDERED: LeagueTier[] = [
  'ruben',
  'simeao',
  'levi',
  'juda',
  'da',
  'naftali',
  'gad',
  'aser',
  'issacar',
  'zebulom',
  'efraim',
  'manasses',
];

export const LEAGUE_TIER_CONFIG: Record<
  LeagueTier,
  {
    display_name: string;
    description: string;
    verse_reference: string;
    color_hex: string;
    emoji: string;
    tier_index: number;
    no_demotion: boolean;
  }
> = {
  ruben: {
    display_name: 'Tribo de Rúben',
    description: 'O primogênito de Jacó. Sua jornada de fé começa aqui.',
    verse_reference: 'Gênesis 29:32',
    color_hex: '#8B4513',
    emoji: '🏕️',
    tier_index: 0,
    no_demotion: true,
  },
  simeao: {
    display_name: 'Tribo de Simeão',
    description: 'Unidos pela fé, crescendo juntos no conhecimento.',
    verse_reference: 'Gênesis 29:33',
    color_hex: '#CD7F32',
    emoji: '⚔️',
    tier_index: 1,
    no_demotion: false,
  },
  levi: {
    display_name: 'Tribo de Levi',
    description: 'Separados para servir. A tribo sacerdotal.',
    verse_reference: 'Gênesis 29:34',
    color_hex: '#C0C0C0',
    emoji: '🕊️',
    tier_index: 2,
    no_demotion: false,
  },
  juda: {
    display_name: 'Tribo de Judá',
    description: 'A tribo real, de onde veio o Leão de Judá.',
    verse_reference: 'Gênesis 29:35',
    color_hex: '#FFD700',
    emoji: '🦁',
    tier_index: 3,
    no_demotion: false,
  },
  da: {
    display_name: 'Tribo de Dã',
    description: 'Justiça e discernimento guiam seus passos.',
    verse_reference: 'Gênesis 30:6',
    color_hex: '#4169E1',
    emoji: '⚖️',
    tier_index: 4,
    no_demotion: false,
  },
  naftali: {
    display_name: 'Tribo de Naftali',
    description: 'Livres como cervos, cheios de bênçãos.',
    verse_reference: 'Gênesis 30:8',
    color_hex: '#2E8B57',
    emoji: '🦌',
    tier_index: 5,
    no_demotion: false,
  },
  gad: {
    display_name: 'Tribo de Gade',
    description: 'Guerreiros valentes, sempre avançando na fé.',
    verse_reference: 'Gênesis 30:11',
    color_hex: '#DC143C',
    emoji: '🛡️',
    tier_index: 6,
    no_demotion: false,
  },
  aser: {
    display_name: 'Tribo de Aser',
    description: 'Abençoados com abundância e favor divino.',
    verse_reference: 'Gênesis 30:13',
    color_hex: '#9370DB',
    emoji: '🫒',
    tier_index: 7,
    no_demotion: false,
  },
  issacar: {
    display_name: 'Tribo de Issacar',
    description: 'Sábios que discernem os tempos e as estações.',
    verse_reference: 'Gênesis 30:18',
    color_hex: '#FF8C00',
    emoji: '📜',
    tier_index: 8,
    no_demotion: false,
  },
  zebulom: {
    display_name: 'Tribo de Zebulom',
    description: 'Navegadores da fé, explorando novos horizontes.',
    verse_reference: 'Gênesis 30:20',
    color_hex: '#00CED1',
    emoji: '⚓',
    tier_index: 9,
    no_demotion: false,
  },
  efraim: {
    display_name: 'Tribo de Efraim',
    description: 'Frutíferos na terra, multiplicando bênçãos.',
    verse_reference: 'Gênesis 41:52',
    color_hex: '#FF1493',
    emoji: '🌿',
    tier_index: 10,
    no_demotion: false,
  },
  manasses: {
    display_name: 'Tribo de Manassés',
    description: 'O ápice da jornada. Deus fez esquecer toda a luta.',
    verse_reference: 'Gênesis 41:51',
    color_hex: '#FFD700',
    emoji: '👑',
    tier_index: 11,
    no_demotion: false,
  },
};

export interface LeaderboardMember {
  user_id: string;
  display_name: string;
  avatar_seed: string;
  faith_points: number;
  rank: number;
  is_mock: boolean;
  is_current_user: boolean;
}

export interface LeaderboardResponse {
  tier: LeagueTier;
  tier_config: (typeof LEAGUE_TIER_CONFIG)[LeagueTier];
  week_key: string;
  starts_at: string;
  ends_at: string;
  members: LeaderboardMember[];
  current_user_rank: number;
  promotion_zone: number;
  demotion_zone: number;
  total_members: number;
}

export type UserPlan = 'free' | 'plus_monthly' | 'plus_annual';
export type CompanyPlan = 'free' | 'basic' | 'professional' | 'enterprise';
export type CompanyType = 'church' | 'school' | 'ngo' | 'company' | 'other';

export type CharacterRarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'special';

declare global {
  namespace Express {
    interface Request {
      user?: {
        userId: string;
        email: string;
        role: 'user' | 'admin' | 'company_admin';
        company_id?: string;
      };
    }
  }
}
