import Redis from 'ioredis';
import { logger } from '../shared/utils/logger';

class RedisClient {
  private static instance: Redis;

  private constructor() {}

  public static getInstance(): Redis {
    if (!RedisClient.instance) {
      const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
      
      RedisClient.instance = new Redis(redisUrl, {
        retryStrategy: (times) => {
          const delay = Math.min(times * 50, 2000);
          logger.warn(`Tentativa ${times} de reconectar ao Redis... (delay: ${delay}ms)`);
          return delay;
        },
      });

      RedisClient.instance.on('connect', () => {
        logger.info('Conectado ao Redis com sucesso!');
      });

      RedisClient.instance.on('error', (err) => {
        logger.error('Erro de conexão com o Redis:', err);
      });
    }

    return RedisClient.instance;
  }
}

const redisInstance = RedisClient.getInstance();

export const redis = {
  // Básico
  get: (key: string): Promise<string | null> => redisInstance.get(key),
  set: (key: string, value: string): Promise<'OK'> => redisInstance.set(key, value),
  setex: (key: string, seconds: number, value: string): Promise<'OK'> => redisInstance.setex(key, seconds, value),
  del: (...keys: string[]): Promise<number> => redisInstance.del(...keys),
  exists: (key: string): Promise<number> => redisInstance.exists(key),
  
  // Sorted Sets
  zadd: (key: string, score: number, member: string): Promise<number | string> => redisInstance.zadd(key, score, member),
  zincrby: (key: string, increment: number, member: string): Promise<string> => redisInstance.zincrby(key, increment, member),
  zrange: (key: string, start: number, stop: number, withScores?: boolean): Promise<string[]> => 
    withScores ? redisInstance.zrange(key, start, stop, 'WITHSCORES') : redisInstance.zrange(key, start, stop),
  zrevrange: (key: string, start: number, stop: number, withScores?: boolean): Promise<string[]> => 
    withScores ? redisInstance.zrevrange(key, start, stop, 'WITHSCORES') : redisInstance.zrevrange(key, start, stop),
  zrank: (key: string, member: string): Promise<number | null> => redisInstance.zrank(key, member),
  zrevrank: (key: string, member: string): Promise<number | null> => redisInstance.zrevrank(key, member),
  zscore: (key: string, member: string): Promise<string | null> => redisInstance.zscore(key, member),
  zcard: (key: string): Promise<number> => redisInstance.zcard(key),
  
  // Hash
  hset: (key: string, field: string, value: string): Promise<number> => redisInstance.hset(key, field, value),
  hget: (key: string, field: string): Promise<string | null> => redisInstance.hget(key, field),
  hgetall: (key: string): Promise<Record<string, string>> => redisInstance.hgetall(key),
  
  // Utilitário
  expire: (key: string, seconds: number): Promise<number> => redisInstance.expire(key, seconds),
  ttl: (key: string): Promise<number> => redisInstance.ttl(key),

  // Client raw
  client: redisInstance,
};
