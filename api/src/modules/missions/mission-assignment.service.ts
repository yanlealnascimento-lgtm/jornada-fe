import { missionRepository } from './mission.repository';
import { getStartOfWeek, getEndOfWeek } from '../../shared/utils/date.util';
import { startOfDay, endOfDay } from 'date-fns';

export class MissionAssignmentService {
  private readonly DAILY_COUNT = 3;
  private readonly WEEKLY_COUNT = 2;

  async assignDailyMissions(userId: string, isPremium = false): Promise<void> {
    const hasActive = await missionRepository.hasActiveMissions(userId, 'daily');
    if (hasActive) return;

    const templates = await missionRepository.findActiveTemplates('daily');
    const eligible = templates.filter((t) => isPremium || !t.is_premium);
    const selected = this.weightedRandomSelect(eligible, this.DAILY_COUNT);

    const now = new Date();
    const cycleStart = startOfDay(now);
    const cycleEnd = endOfDay(now);

    for (const template of selected) {
      const title = template.title.replace('{target}', template.target.toString());
      await missionRepository.createForUser({
        user_id: userId as never,
        template_id: template._id as never,
        title,
        description: template.description,
        icon_emoji: template.icon_emoji,
        cycle: 'daily',
        trigger: template.trigger,
        target: template.target,
        difficulty: template.difficulty,
        pf_reward: template.pf_reward,
        mana_reward: template.mana_reward,
        verse_reference: template.verse_reference,
        verse_text: template.verse_text,
        progress: 0,
        status: 'active',
        cycle_start: cycleStart,
        cycle_end: cycleEnd,
      });
    }
  }

  async assignWeeklyMissions(userId: string, isPremium = false): Promise<void> {
    const hasActive = await missionRepository.hasActiveMissions(userId, 'weekly');
    if (hasActive) return;

    const templates = await missionRepository.findActiveTemplates('weekly');
    const eligible = templates.filter((t) => isPremium || !t.is_premium);
    const selected = this.weightedRandomSelect(eligible, this.WEEKLY_COUNT);

    const cycleStart = getStartOfWeek();
    const cycleEnd = getEndOfWeek();

    for (const template of selected) {
      const title = template.title.replace('{target}', template.target.toString());
      await missionRepository.createForUser({
        user_id: userId as never,
        template_id: template._id as never,
        title,
        description: template.description,
        icon_emoji: template.icon_emoji,
        cycle: 'weekly',
        trigger: template.trigger,
        target: template.target,
        difficulty: template.difficulty,
        pf_reward: template.pf_reward,
        mana_reward: template.mana_reward,
        verse_reference: template.verse_reference,
        verse_text: template.verse_text,
        progress: 0,
        status: 'active',
        cycle_start: cycleStart,
        cycle_end: cycleEnd,
      });
    }
  }

  private weightedRandomSelect<T extends { weight: number }>(items: T[], count: number): T[] {
    if (items.length <= count) return items;
    const selected: T[] = [];
    const pool = [...items];
    while (selected.length < count && pool.length > 0) {
      const totalWeight = pool.reduce((sum, i) => sum + i.weight, 0);
      let rng = Math.random() * totalWeight;
      const idx = pool.findIndex((item) => {
        rng -= item.weight;
        return rng <= 0;
      });
      const pick = pool.splice(Math.max(idx, 0), 1)[0];
      selected.push(pick);
    }
    return selected;
  }
}

export const missionAssignmentService = new MissionAssignmentService();
