import cron from 'node-cron';
import { LeagueService } from '../leagues/league.service';
import { StreakService } from '../gamification/streak.service';
import { logger } from '../../shared/utils/logger';

export const startNotificationScheduler = () => {
    logger.info('🕒 Schedulers Inicializados.');
    const leagueService = new LeagueService();
    const streakService = new StreakService();

    // 1. Segunda-feira 00:01 = Processa a promoção de ligas
    cron.schedule('1 0 * * 1', async () => {
        logger.info('[CRON] Initiating weekly League Promotion processing...');
        await leagueService.processWeeklyPromotion();
    });

    // 2. Todos os dias às 18:00 = Lembretes de Streak Moderado
    cron.schedule('0 18 * * *', async () => {
        logger.info('[CRON] Checking users at risk for their streak at 18h...');
        const usersInRisk = await streakService.getUsersAtRiskToday();
        logger.info(`[FCM-SIMULADO] Enviando Lembrete Suave para ${usersInRisk.length} usuários atrasados.`);
    });

    // 3. Todos os dias às 23:00 = Lembrete Urgente
    cron.schedule('0 23 * * *', async () => {
        logger.info('[CRON] Checking users at VERY risk for their streak at 23h...');
        const usersInRisk = await streakService.getUsersAtRiskToday();
        logger.info(`[FCM-SIMULADO] Enviando ALERTA VERMELHO para ${usersInRisk.length} usuários em risco extremo.`);
    });
};
