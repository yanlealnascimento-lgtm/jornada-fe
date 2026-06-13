import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { errorMiddleware } from './shared/middleware/error.middleware';
import userRoutes from './modules/users/user.routes';
import contentRoutes from './modules/content/content.routes';
import gamificationRoutes from './modules/gamification/gamification.routes';
import companyRoutes from './modules/companies/company.routes';

import adminRoutes from './modules/admin/admin.routes';
import authRoutes from './modules/auth/auth.routes';
import exerciseRoutes from './modules/content/exercise.routes';
import { trailPublicRoutes, trailAdminRoutes } from './modules/content/trail.routes';
import { characterPublicRoutes, characterAdminRoutes } from './modules/content/character.routes';
import { leaguePublicRoutes, leagueAdminRoutes } from './modules/leagues/league.routes';
import { achievementPublicRoutes, achievementAdminRoutes } from './modules/gamification/achievement.routes';
// Missions removed — merged into achievements
// import { missionPublicRoutes, missionAdminRoutes } from './modules/missions/mission.routes';
import { unitAdminRoutes } from './modules/content/unit.routes';
import { lessonAdminRoutes } from './modules/content/lesson.routes';
import { exerciseAdminRoutes } from './modules/content/exercise.routes';
import { studyPublicRoutes, studyAdminRoutes } from './modules/study/study.routes';
import { lessonProgressRoutes } from './modules/content/lesson-progress.routes';

const app = express();

app.use(helmet({ contentSecurityPolicy: false })); // Desabilitar CSP em dev para evitar bloqueios locais
app.use(cors({ 
  origin: (origin, callback) => {
    // Permite qualquer porta do localhost/127.0.0.1 durante desenvolvimento
    if (!origin || /https?:\/\/localhost|127\.0\.0\.1/.test(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-User-Id'],
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(morgan('dev'));

// Rotas Administrativas (CRUD Direto)
app.use('/api/v1', adminRoutes);
app.use('/api/v1/auth', authRoutes);

// Rotas dedicadas de Trilhas
app.use('/api/v1/trails',       trailPublicRoutes);
app.use('/api/v1/admin/trails', trailAdminRoutes);

// Rotas dedicadas de Personagens
app.use('/api/v1/characters',       characterPublicRoutes);
app.use('/api/v1/admin/characters', characterAdminRoutes);

// Rotas dedicadas de Conquistas
app.use('/api/v1/achievements',       achievementPublicRoutes);
app.use('/api/v1/admin/achievements', achievementAdminRoutes);

// Rotas dedicadas de Units e Lessons
// Rotas de progresso de lições (etapas)
app.use('/api/v1/lessons', lessonProgressRoutes);

app.use('/api/v1/admin/units',     unitAdminRoutes);
app.use('/api/v1/admin/lessons',   lessonAdminRoutes);
app.use('/api/v1/admin/exercises', exerciseAdminRoutes);

// Missions removed — merged into achievements

// Rotas dedicadas de Ligas
app.use('/api/v1/leagues',       leaguePublicRoutes);
app.use('/api/v1/admin/leagues', leagueAdminRoutes);

// Rotas dedicadas de Estudos Bíblicos
app.use('/api/v1/studies',       studyPublicRoutes);
app.use('/api/v1/admin/studies', studyAdminRoutes);

// Rotas de Jogo e Usuário
app.use('/api/v1/exercises', exerciseRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/content', contentRoutes);
app.use('/api/v1/gamification', gamificationRoutes);
app.use('/api/v1/companies', companyRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

app.use(errorMiddleware);

export default app;
