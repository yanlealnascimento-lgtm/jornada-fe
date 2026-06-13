import 'dotenv/config';
import app from './src/app';
import { connectDB } from './src/config/database';
import { redis } from './src/config/redis';
import { logger } from './src/shared/utils/logger';
import { startNotificationScheduler } from './src/modules/notifications/notification.scheduler';

const PORT = process.env.PORT || 4000;

const startServer = async () => {
  try {
    // 1. Conectar MongoDB
    await connectDB();
    
    // 2. Conectar Redis aguardando o pronto via ping
    await redis.client.ping();
    logger.info('Redis está pronto para operações!');
    
    // Start Cronjobs
    startNotificationScheduler();

    // 3. Inicializar Firebase Admin (placeholder)
    // if (process.env.FIREBASE_PROJECT_ID) {
    //   initFirebase();
    // }

    // 4. Iniciar o Express
    app.listen(Number(PORT), '0.0.0.0', () => {
      logger.info(`🚀 Servidor rodando em http://0.0.0.0:${PORT} | Env: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    logger.error('❌ Erro fatal ao iniciar o servidor:', error);
    process.exit(1);
  }
};

startServer();
