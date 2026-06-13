// notification.service.ts
// Serviço de Push Notifications via Firebase Cloud Messaging (FCM)
// ATENÇÃO: Requer configuração do Firebase Admin SDK (ver Prompt 18 / .env.example)

// import { getMessaging } from 'firebase-admin/messaging';
// import { createClient } from 'redis';

export interface NotificationPayload {
  title: string;
  body: string;
  imageUrl?: string;
  data?: Record<string, string>;
}

export type LeagueTier = 'bronze' | 'silver' | 'gold' | 'sapphire' | 'onyx' | 'diamond';

export interface IUser {
  _id: { toString(): string };
  name: string;
  streak_current: number;
  fcm_token?: string;
}

export interface IAchievement {
  name: string;
  description: string;
  pf_reward: number;
}

export class NotificationService {
  // private messaging = getMessaging();
  // private redis = createClient({ url: process.env.REDIS_URL });

  // Envia notificação para um único usuário via FCM token
  async sendToUser(userId: string, payload: NotificationPayload): Promise<void> {
    // Buscar FCM token do usuário
    // const user = await UserRepository.findById(userId);
    // if (!user?.fcm_token) return;

    // await this.messaging.send({
    //   token: user.fcm_token,
    //   notification: { title: payload.title, body: payload.body, imageUrl: payload.imageUrl },
    //   data: payload.data,
    //   android: { priority: 'high' },
    //   apns: { payload: { aps: { sound: 'default', badge: 1 } } },
    // });

    console.log(`[FCM] Notificação para userId=${userId}: ${payload.title} — ${payload.body}`);
  }

  // Envia para múltiplos usuários (batch — máximo 500 por chamada FCM)
  async sendToUsers(userIds: string[], payload: NotificationPayload): Promise<void> {
    const BATCH_SIZE = 500;
    for (let i = 0; i < userIds.length; i += BATCH_SIZE) {
      const batch = userIds.slice(i, i + BATCH_SIZE);
      await Promise.allSettled(batch.map((id) => this.sendToUser(id, payload)));
    }
  }

  // Lembrete de streak — enviado quando falta pouco para meia-noite e usuário não fez lição
  async sendStreakReminder(user: IUser): Promise<void> {
    if (!(await this.canSendEngagementNotification(user._id.toString()))) return;

    const messages = [
      `${user.name}, sua sequência de ${user.streak_current} dias vai apagar em breve! 🔥`,
      `Caleb está esperando por você! Não deixe sua vela de ${user.streak_current} dias apagar! 🕯️`,
      `"Seja constante na oração" (Rm 12:12). Sua lição diária te espera! ✝️`,
      `${user.name}, só falta uma lição para manter sua devoção hoje! 📖`,
    ];
    const body = messages[Math.floor(Math.random() * messages.length)];

    await this.sendToUser(user._id.toString(), {
      title: 'Dia de Devoção ⏰',
      body,
      data: { type: 'streak_reminder', screen: '/home' },
    });
  }

  // Mensagem de encorajamento quando streak é quebrado — nunca punitiva
  async sendStreakBroken(user: IUser): Promise<void> {
    const messages = [
      `A vela apagou... mas cada novo dia é uma nova oportunidade! Volte hoje! 💪`,
      `Caleb ainda acredita em você! "Renovemos nossos propósitos de manhã em manhã." — Lm 3:23`,
      `Todos tropeçam. O que importa é se levantar. Sua jornada recomeça agora! 🌅`,
      `${user.name}, um novo dia começa! Recomeçar é uma bênção. 🙏`,
    ];
    const body = messages[Math.floor(Math.random() * messages.length)];

    await this.sendToUser(user._id.toString(), {
      title: 'Reacenda sua chama! 🕯️',
      body,
      data: { type: 'streak_broken', screen: '/home' },
    });
  }

  // Celebração de marcos de streak: 3, 7, 14, 21, 30, 60, 90, 180, 365 dias
  async sendStreakMilestone(user: IUser, days: number): Promise<void> {
    const milestoneVerses: Record<number, string> = {
      3: '"O início da sabedoria é o temor do Senhor" — Sl 111:10',
      7: '"Sete vezes cai o justo e se levanta" — Pv 24:16',
      14: '"Sê fiel até à morte" — Ap 2:10',
      21: '"Tudo o que fizerem, façam de todo o coração" — Cl 3:23',
      30: '"Seja constante na oração" — Rm 12:12',
      60: '"Persevera nas coisas que aprendeste" — 2Tm 3:14',
      90: '"Aquele que perseverar até ao fim será salvo" — Mt 24:13',
      180: '"Bem-aventurado o homem que não anda segundo o conselho dos ímpios" — Sl 1:1',
      365: '"Mais um ano de bênçãos!" — Sua família JourneyFaith 🙏',
    };

    await this.sendToUser(user._id.toString(), {
      title: `🔥 ${days} dias de devoção! Incrível, ${user.name}!`,
      body: milestoneVerses[days] ?? `${days} dias seguidos! Continue firme na fé!`,
      data: { type: 'streak_milestone', screen: '/home', days: days.toString() },
    });
  }

  // Promoção de liga
  async sendLeaguePromotion(user: IUser, newTier: LeagueTier): Promise<void> {
    const tierNames: Record<LeagueTier, string> = {
      bronze: 'Bronze', silver: 'Prata', gold: 'Ouro',
      sapphire: 'Safira', onyx: 'Ônix', diamond: 'Diamante',
    };
    await this.sendToUser(user._id.toString(), {
      title: `🎉 Subiu de liga! Bem-vindo à ${tierNames[newTier]}!`,
      body: `${user.name}, seu esforço foi recompensado! Continue firme. "Correi de tal maneira que possais ganhar" — 1Co 9:24`,
      data: { type: 'league_promotion', screen: '/leagues', tier: newTier },
    });
  }

  // Rebaixamento de liga — tom encorajador, nunca punitivo
  async sendLeagueDemotion(user: IUser, newTier: LeagueTier): Promise<void> {
    const tierNames: Record<LeagueTier, string> = {
      bronze: 'Bronze', silver: 'Prata', gold: 'Ouro',
      sapphire: 'Safira', onyx: 'Ônix', diamond: 'Diamante',
    };
    await this.sendToUser(user._id.toString(), {
      title: `${user.name}, nova semana, nova chance! 💪`,
      body: `Você está na Liga ${tierNames[newTier]}. "Renovemos nossos propósitos de manhã em manhã" — Lm 3:23`,
      data: { type: 'league_demotion', screen: '/leagues', tier: newTier },
    });
  }

  // Aviso de fim de liga (quando falta 24h)
  async sendLeagueEnding(user: IUser, rank: number, tier: LeagueTier): Promise<void> {
    const isInPromotion = rank <= 10;
    const isInDemotion = rank > 25;

    let title: string;
    let body: string;

    if (isInPromotion) {
      title = `🏆 Você está na zona de promoção! #${rank}`;
      body = `${user.name}, falta menos de 24h! Mantenha sua posição e suba de liga!`;
    } else if (isInDemotion) {
      title = `⚠️ Liga encerra em 24h — posição #${rank}`;
      body = `${user.name}, ainda dá tempo! Faça suas lições e suba no ranking! "Persevera!" 💪`;
    } else {
      title = `Liga encerra amanhã! Posição #${rank}`;
      body = `${user.name}, continue assim! Só mais um dia de devoção.`;
    }

    await this.sendToUser(user._id.toString(), {
      title,
      body,
      data: { type: 'league_ending', screen: '/leagues', rank: rank.toString() },
    });
  }

  // Conquista desbloqueada
  async sendAchievementUnlocked(user: IUser, achievement: IAchievement): Promise<void> {
    await this.sendToUser(user._id.toString(), {
      title: `🏅 Nova Conquista: ${achievement.name}!`,
      body: `${user.name}, você ganhou "${achievement.name}"! +${achievement.pf_reward} PF`,
      data: { type: 'achievement', screen: '/profile' },
    });
  }

  // Novo conteúdo disponível (nova trilha publicada)
  async sendNewContent(userIds: string[], trailTitle: string): Promise<void> {
    await this.sendToUsers(userIds, {
      title: `📖 Nova Trilha disponível!`,
      body: `"${trailTitle}" acabou de ser publicada. Comece sua jornada!`,
      data: { type: 'new_content', screen: '/home' },
    });
  }

  // Rate limiting: máximo 2 notificações de engajamento por usuário por dia
  async canSendEngagementNotification(userId: string): Promise<boolean> {
    // Implementação com Redis:
    // const key = `notif:engagement:${userId}:${new Date().toISOString().slice(0, 10)}`;
    // const count = await this.redis.incr(key);
    // if (count === 1) await this.redis.expire(key, 86400); // TTL 24h
    // return count <= 2;
    return true; // MVP: sem rate limiting
  }

  // Enviar para todos os usuários em risco de streak (sem lição hoje)
  async sendLeagueEndingNotifications(): Promise<void> {
    // const usersAtRisk = await LeagueRepository.getUsersInEndingLeagues();
    // for (const { user, rank, tier } of usersAtRisk) {
    //   await this.sendLeagueEnding(user, rank, tier);
    // }
    console.log('[FCM] sendLeagueEndingNotifications chamado');
  }
}

export const notificationService = new NotificationService();
