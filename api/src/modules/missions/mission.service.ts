import { missionRepository } from './mission.repository';
import { missionAssignmentService } from './mission-assignment.service';
import { missionEngine, MissionEventContext } from './mission.engine';
import { SEED_MISSION_TEMPLATES } from '../../config/seeds/mission.seed';

export class MissionService {
  // ─── Templates (admin) ──────────────────────────────────────────────────
  async listTemplates(filters: Record<string, unknown>) {
    return missionRepository.findAllTemplates(filters as never);
  }

  async getTemplateById(id: string) {
    const t = await missionRepository.findTemplateById(id);
    if (!t) throw new Error('TEMPLATE_NOT_FOUND');
    return t;
  }

  async createTemplate(data: Record<string, unknown>) {
    return missionRepository.createTemplate(data as never);
  }

  async updateTemplate(id: string, data: Record<string, unknown>) {
    const t = await missionRepository.updateTemplate(id, data as never);
    if (!t) throw new Error('TEMPLATE_NOT_FOUND');
    return t;
  }

  async deleteTemplate(id: string) {
    if (!(await missionRepository.deleteTemplate(id))) throw new Error('TEMPLATE_NOT_FOUND');
    return { deleted: true };
  }

  async getStats() {
    return missionRepository.getTemplateStats();
  }

  async runSeed() {
    return missionRepository.seedMany(SEED_MISSION_TEMPLATES as never[]);
  }

  // ─── Missões do usuário (app) ────────────────────────────────────────────
  async getUserMissions(userId: string, isPremium = false) {
    await missionAssignmentService.assignDailyMissions(userId, isPremium);
    await missionAssignmentService.assignWeeklyMissions(userId, isPremium);

    const active = await missionRepository.findActiveForUser(userId);
    const daily = active.filter((x) => x.cycle === 'daily');
    const weekly = active.filter((x) => x.cycle === 'weekly');

    return { daily, weekly };
  }

  async processEvent(ctx: MissionEventContext) {
    return missionEngine.processEvent(ctx);
  }

  async getMissionHistory(userId: string) {
    return missionRepository.findCompletedForUser(userId);
  }

  async getUserStats(userId: string) {
    return missionRepository.getUserMissionStats(userId);
  }

  async expireOldMissions() {
    return missionRepository.expireOldMissions();
  }
}

export const missionService = new MissionService();
