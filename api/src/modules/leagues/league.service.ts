import {
  LeagueTier,
  LEAGUE_TIERS_ORDERED,
  LEAGUE_TIER_CONFIG,
  LeaderboardMember,
} from '../../shared/types';
import { LeagueModel, LeagueMemberModel } from './league.model';
import { UserModel } from '../users/user.model';
import { getWeekKey, getStartOfWeek, getEndOfWeek } from '../../shared/utils/date.util';
import { generateMockLeagueMembers } from '../../config/seeds/league-mock-users.seed';

const PROMOTION_COUNT = 5;
const DEMOTION_COUNT = 5;

export class LeagueService {
  // ─── Seed Current Week ──────────────────────────────────────────────
  // Creates League docs for all 12 tiers and populates LeagueMembers
  // with mock (bot) users. Uses upsert so it is idempotent.
  async seedCurrentWeek(): Promise<{ leagues_created: number; mocks_created: number }> {
    const weekKey = getWeekKey();
    const startsAt = getStartOfWeek();
    const endsAt = getEndOfWeek();

    let leaguesCreated = 0;
    let mocksCreated = 0;

    // 1. Ensure a League document exists for every tier this week
    for (const tier of LEAGUE_TIERS_ORDERED) {
      const result = await LeagueModel.findOneAndUpdate(
        { week_key: weekKey, tier, group_id: 0 },
        {
          $setOnInsert: {
            tier,
            week_key: weekKey,
            group_id: 0,
            max_members: 30,
            starts_at: startsAt,
            ends_at: endsAt,
            is_active: true,
            processed: false,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      );
      if (result.createdAt.getTime() === result.updatedAt.getTime()) {
        leaguesCreated++;
      }
    }

    // 2. Populate mock users for every tier
    const mocks = generateMockLeagueMembers();

    for (const mock of mocks) {
      const league = await LeagueModel.findOne({
        week_key: weekKey,
        tier: mock.tier,
        group_id: 0,
      }).lean();
      if (!league) continue;

      const mockId = mock.avatar_seed; // unique per tier: "mock_<tier>_<i>"

      const res = await LeagueMemberModel.updateOne(
        { user_id: mockId, week_key: weekKey },
        {
          $setOnInsert: {
            league_id: league!._id,
            user_id: mockId,
            display_name: mock.display_name,
            avatar_seed: mock.avatar_seed,
            faith_points: mock.faith_points,
            is_mock: true,
            week_key: weekKey,
            tier: mock.tier,
          },
        },
        { upsert: true },
      );
      if (res.upsertedCount > 0) mocksCreated++;
    }

    // 3. Update member counts
    for (const tier of LEAGUE_TIERS_ORDERED) {
      const count = await LeagueMemberModel.countDocuments({ week_key: weekKey, tier });
      await LeagueModel.updateOne(
        { week_key: weekKey, tier, group_id: 0 },
        { $set: { member_count: count } },
      );
    }

    return { leagues_created: leaguesCreated, mocks_created: mocksCreated };
  }

  // ─── Add PF to League ───────────────────────────────────────────────
  // Find or create a LeagueMember for the real user, increment faith_points.
  // Returns the user's new position (1-indexed).
  async addPFToLeague(
    userId: string,
    tier: LeagueTier,
    weekKey: string,
    pfAmount: number,
  ): Promise<{ position: number; faith_points: number }> {
    // Ensure League exists
    let league = await LeagueModel.findOne({ week_key: weekKey, tier, group_id: 0 }).lean();
    if (!league) {
      // Auto-create league if it doesn't exist yet
      const startsAt = getStartOfWeek();
      const endsAt = getEndOfWeek();
      const created = await LeagueModel.create({
        tier,
        week_key: weekKey,
        group_id: 0,
        max_members: 30,
        starts_at: startsAt,
        ends_at: endsAt,
        is_active: true,
        processed: false,
      });
      league = created.toObject() as any;
    }

    // Get user info for display_name and avatar
    const user = await UserModel.findById(userId).select('name avatar_url').lean();
    const displayName = user?.name || 'Jogador';
    const avatarSeed = user?.avatar_url || userId;

    // Upsert the LeagueMember and increment faith_points
    await LeagueMemberModel.updateOne(
      { user_id: userId, week_key: weekKey },
      {
        $inc: { faith_points: pfAmount },
        $setOnInsert: {
          league_id: league!._id,
          user_id: userId,
          display_name: displayName,
          avatar_seed: avatarSeed,
          is_mock: false,
          week_key: weekKey,
          tier,
        },
      },
      { upsert: true },
    );

    // Update member count
    const memberCount = await LeagueMemberModel.countDocuments({ week_key: weekKey, tier });
    await LeagueModel.updateOne(
      { week_key: weekKey, tier, group_id: 0 },
      { $set: { member_count: memberCount } },
    );

    // Compute new position
    const member = await LeagueMemberModel.findOne({ user_id: userId, week_key: weekKey }).lean();
    const position = member
      ? (await LeagueMemberModel.countDocuments({
          week_key: weekKey,
          tier,
          faith_points: { $gt: member.faith_points },
        })) + 1
      : 0;

    return { position, faith_points: member?.faith_points ?? 0 };
  }

  // ─── Get User League ────────────────────────────────────────────────
  // Returns the full leaderboard for the user's current tier with
  // promotion/demotion zones marked.
  async getUserLeague(userId: string): Promise<{
    tier: LeagueTier;
    tier_config: (typeof LEAGUE_TIER_CONFIG)[LeagueTier];
    week_key: string;
    starts_at: Date;
    ends_at: Date;
    members: LeaderboardMember[];
    current_user_rank: number;
    promotion_zone: number;
    demotion_zone: number;
    total_members: number;
  }> {
    const user = await UserModel.findById(userId).select('league_tier').lean();
    if (!user) throw new Error('Usuário não encontrado');

    const tier = (user.league_tier as LeagueTier) || 'ruben';
    const weekKey = getWeekKey();
    const tierConfig = LEAGUE_TIER_CONFIG[tier];

    // Find the league document
    const league = await LeagueModel.findOne({
      week_key: weekKey,
      tier,
      group_id: 0,
    }).lean();

    if (!league) {
      // League not seeded yet - auto-seed and assign user
      await this.seedCurrentWeek();
      await this.assignUserToLeague(userId, tier);

      // Re-fetch after seeding
      return this.getUserLeague(userId);
    }

    // Ensure the current user is a member of this week's league
    const existingMember = await LeagueMemberModel.findOne({ user_id: userId, week_key: weekKey }).lean();
    if (!existingMember) {
      await this.assignUserToLeague(userId, tier);
    }

    // Query all members sorted by faith_points descending
    const allMembers = await LeagueMemberModel.find({
      week_key: weekKey,
      tier,
    })
      .sort({ faith_points: -1 })
      .lean();

    const totalMembers = allMembers.length;
    const demotionStartRank = tierConfig.no_demotion ? totalMembers + 1 : totalMembers - DEMOTION_COUNT + 1;

    let currentUserRank = 0;

    const members: LeaderboardMember[] = allMembers.map((m, idx) => {
      const rank = idx + 1;
      const isCurrentUser = m.user_id === userId;
      if (isCurrentUser) currentUserRank = rank;

      return {
        user_id: m.user_id,
        display_name: m.display_name,
        avatar_seed: m.avatar_seed,
        faith_points: m.faith_points,
        rank,
        is_mock: m.is_mock,
        is_current_user: isCurrentUser,
      };
    });

    return {
      tier,
      tier_config: tierConfig,
      week_key: weekKey,
      starts_at: league.starts_at,
      ends_at: league.ends_at,
      members,
      current_user_rank: currentUserRank,
      promotion_zone: PROMOTION_COUNT,
      demotion_zone: demotionStartRank,
      total_members: totalMembers,
    };
  }

  // ─── Process Weekly Promotion ───────────────────────────────────────
  // For each tier, promote top 5 real users and demote bottom 5 real
  // users (except in the lowest tier "ruben"). Updates user.league_tier.
  async processWeeklyPromotion(): Promise<{
    promoted: number;
    demoted: number;
  }> {
    const weekKey = getWeekKey();
    let totalPromoted = 0;
    let totalDemoted = 0;

    for (let i = 0; i < LEAGUE_TIERS_ORDERED.length; i++) {
      const tier = LEAGUE_TIERS_ORDERED[i];
      const league = await LeagueModel.findOne({ week_key: weekKey, tier, group_id: 0 });
      if (!league || league.processed) continue;

      // Get real users sorted by faith_points DESC
      const realMembers = await LeagueMemberModel.find({
        week_key: weekKey,
        tier,
        is_mock: false,
      })
        .sort({ faith_points: -1 })
        .lean();

      if (realMembers.length === 0) {
        league.processed = true;
        await league.save();
        continue;
      }

      const promotedUserIds: string[] = [];
      const demotedUserIds: string[] = [];

      // ─ Promotion: top N real users go up one tier (except from the highest tier)
      if (i < LEAGUE_TIERS_ORDERED.length - 1) {
        const nextTier = LEAGUE_TIERS_ORDERED[i + 1];
        const toPromote = realMembers.slice(0, PROMOTION_COUNT);

        for (const m of toPromote) {
          await UserModel.findByIdAndUpdate(m.user_id, { league_tier: nextTier });
          promotedUserIds.push(m.user_id);
          totalPromoted++;
        }
      }

      // ─ Demotion: bottom N real users go down one tier (except from "ruben")
      const tierConfig = LEAGUE_TIER_CONFIG[tier];
      if (!tierConfig.no_demotion && i > 0) {
        const prevTier = LEAGUE_TIERS_ORDERED[i - 1];
        const toDemote = realMembers.slice(-DEMOTION_COUNT);

        for (const m of toDemote) {
          // Don't demote someone who was just promoted
          if (promotedUserIds.includes(m.user_id)) continue;
          await UserModel.findByIdAndUpdate(m.user_id, { league_tier: prevTier });
          demotedUserIds.push(m.user_id);
          totalDemoted++;
        }
      }

      // Mark league as processed
      league.processed = true;
      league.set('promoted_users', promotedUserIds);
      league.set('demoted_users', demotedUserIds);
      await league.save();
    }

    return { promoted: totalPromoted, demoted: totalDemoted };
  }

  // ─── Assign User to League ─────────────────────────────────────────
  // Sets the user's league_tier in UserModel and optionally adds them
  // as a LeagueMember for the current week.
  async assignUserToLeague(userId: string, tier: LeagueTier): Promise<void> {
    await UserModel.findByIdAndUpdate(userId, { league_tier: tier });

    const weekKey = getWeekKey();

    // Ensure league exists
    let league = await LeagueModel.findOne({ week_key: weekKey, tier, group_id: 0 }).lean();
    if (!league) {
      const startsAt = getStartOfWeek();
      const endsAt = getEndOfWeek();
      const created = await LeagueModel.create({
        tier,
        week_key: weekKey,
        group_id: 0,
        max_members: 30,
        starts_at: startsAt,
        ends_at: endsAt,
        is_active: true,
        processed: false,
      });
      league = created.toObject() as any;
    }

    // Get user info
    const user = await UserModel.findById(userId).select('name avatar_url').lean();
    const displayName = user?.name || 'Jogador';
    const avatarSeed = user?.avatar_url || userId;

    // Upsert member
    await LeagueMemberModel.updateOne(
      { user_id: userId, week_key: weekKey },
      {
        $set: {
          league_id: league!._id,
          user_id: userId,
          display_name: displayName,
          avatar_seed: avatarSeed,
          is_mock: false,
          week_key: weekKey,
          tier,
        },
        $setOnInsert: { faith_points: 0 },
      },
      { upsert: true },
    );

    // Update member count
    const count = await LeagueMemberModel.countDocuments({ week_key: weekKey, tier });
    await LeagueModel.updateOne(
      { week_key: weekKey, tier, group_id: 0 },
      { $set: { member_count: count } },
    );
  }
}

export const leagueService = new LeagueService();
