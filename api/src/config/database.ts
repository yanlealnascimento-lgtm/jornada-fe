import mongoose from 'mongoose';
import { logger } from '../shared/utils/logger';

export const connectDB = async (): Promise<void> => {
  const uri = process.env.MONGODB_URI;

  if (!uri) {
    logger.error('MONGODB_URI não está definido nas variáveis de ambiente.');
    process.exit(1);
  }

  if (process.env.NODE_ENV === 'development') {
    mongoose.set('debug', true);
  }

  let retries = 5;

  const connectWithRetry = async () => {
    try {
      logger.info('Tentando conectar ao MongoDB...');
      await mongoose.connect(uri);
      logger.info('Conectado ao MongoDB com sucesso!');
    } catch (err: any) {
      retries -= 1;
      logger.error(`Erro ao conectar ao MongoDB. Retentando em 5 segundos... Tentativas restantes: ${retries}`, err);
      if (retries === 0) {
        process.exit(1);
      }
      setTimeout(connectWithRetry, 5000);
    }
  };

  mongoose.connection.on('disconnected', () => {
    logger.warn('MongoDB desconectado.');
  });

  mongoose.connection.on('error', (err) => {
    logger.error('Erro de conexão do MongoDB.', err);
  });

  await connectWithRetry();
};

export { mongoose };
