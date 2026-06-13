export const logger = {
  info: (message: string, ...meta: any[]) => {
    if (process.env.NODE_ENV === 'production') {
      console.log(JSON.stringify({ level: 'info', message, timestamp: new Date().toISOString(), ...meta }));
    } else {
      console.log(`[INFO] ${new Date().toISOString()} - ${message}`, ...meta);
    }
  },
  warn: (message: string, ...meta: any[]) => {
    if (process.env.NODE_ENV === 'production') {
      console.warn(JSON.stringify({ level: 'warn', message, timestamp: new Date().toISOString(), ...meta }));
    } else {
      console.warn(`[WARN] ${new Date().toISOString()} - ${message}`, ...meta);
    }
  },
  error: (message: string, error?: any, ...meta: any[]) => {
    if (process.env.NODE_ENV === 'production') {
      console.error(JSON.stringify({ level: 'error', message, error: error?.message || error, stack: error?.stack, timestamp: new Date().toISOString(), ...meta }));
    } else {
      console.error(`[ERROR] ${new Date().toISOString()} - ${message}`, error || '', ...meta);
    }
  },
  debug: (message: string, ...meta: any[]) => {
    if (process.env.NODE_ENV === 'development') {
      console.debug(`[DEBUG] ${new Date().toISOString()} - ${message}`, ...meta);
    }
  }
};
