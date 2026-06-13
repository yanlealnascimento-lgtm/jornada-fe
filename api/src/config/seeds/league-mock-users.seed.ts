import { LeagueTier, LEAGUE_TIERS_ORDERED } from '../../shared/types';

// ── 29 biblical names that cycle for every tier ───────────────────────

const BIBLICAL_NAMES: string[] = [
  'Abraão',
  'Sara',
  'Moisés',
  'Raabe',
  'Davi',
  'Ester',
  'Elias',
  'Rute',
  'Samuel',
  'Miriã',
  'Josué',
  'Débora',
  'Daniel',
  'Ana',
  'Isaías',
  'Lídia',
  'Jeremias',
  'Noemi',
  'Ezequiel',
  'Rebeca',
  'Neemias',
  'Raquel',
  'Calebe',
  'Abigail',
  'Gideão',
  'Maria',
  'Sansão',
  'Talita',
  'Barnabé',
];

// ── Faith-point ranges per tier ───────────────────────────────────────

const TIER_FP_RANGES: Record<LeagueTier, { min: number; max: number }> = {
  ruben:    { min: 50,   max: 300 },
  simeao:   { min: 200,  max: 500 },
  levi:     { min: 400,  max: 700 },
  juda:     { min: 600,  max: 900 },
  da:       { min: 800,  max: 1100 },
  naftali:  { min: 1000, max: 1400 },
  gad:      { min: 1300, max: 1700 },
  aser:     { min: 1600, max: 2000 },
  issacar:  { min: 1900, max: 2400 },
  zebulom:  { min: 2300, max: 2800 },
  efraim:   { min: 2700, max: 3300 },
  manasses: { min: 3200, max: 4000 },
};

// ── Types ─────────────────────────────────────────────────────────────

export interface MockLeagueMember {
  display_name: string;
  avatar_seed: string;
  faith_points: number;
  is_mock: true;
  tier: LeagueTier;
}

// ── Decreasing distribution helper ───────────────────────────────────
// Position 0 (rank 1) gets the highest FP, position 28 (rank 29) the lowest.
// Uses a simple linear interpolation from max → min.

function computeFaithPoints(
  position: number,
  totalPositions: number,
  min: number,
  max: number,
): number {
  // ratio goes from 1.0 (position 0) to 0.0 (last position)
  const ratio = 1 - position / (totalPositions - 1);
  const fp = Math.round(min + ratio * (max - min));
  return fp;
}

// ── Generator ─────────────────────────────────────────────────────────

const MOCK_COUNT_PER_TIER = 29;

export function generateMockLeagueMembers(): MockLeagueMember[] {
  const members: MockLeagueMember[] = [];

  for (const tier of LEAGUE_TIERS_ORDERED) {
    const { min, max } = TIER_FP_RANGES[tier];

    for (let i = 0; i < MOCK_COUNT_PER_TIER; i++) {
      const name = BIBLICAL_NAMES[i % BIBLICAL_NAMES.length];
      const fp = computeFaithPoints(i, MOCK_COUNT_PER_TIER, min, max);

      members.push({
        display_name: name,
        avatar_seed: `mock_${tier}_${i}`,
        faith_points: fp,
        is_mock: true,
        tier,
      });
    }
  }

  return members;
}

// ── Pre-built constant (348 mocks: 12 tiers × 29) ────────────────────

export const LEAGUE_MOCK_USERS: MockLeagueMember[] = generateMockLeagueMembers();
