import winston from 'winston';
import { SERVER_CONFIG } from './config';

const logFormat = winston.format.printf(({ level, message, timestamp, ...meta }) => {
  let msg = `${timestamp} [${level}]: ${message}`;
  if (Object.keys(meta).length > 0) {
    msg += ` ${JSON.stringify(meta)}`;
  }
  return msg;
});

export const logger = winston.createLogger({
  level: SERVER_CONFIG.LOG_LEVEL,
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple(),
        logFormat
      )
    }),
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      )
    }),
    new winston.transports.File({
      filename: 'logs/combined.log',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      )
    })
  ],
  exceptionHandlers: [
    new winston.transports.File({ filename: 'logs/exceptions.log' })
  ],
  rejectionHandlers: [
    new winston.transports.File({ filename: 'logs/rejections.log' })
  ]
});

// Create a child logger for specific modules
export const createLogger = (module: string) => {
  return logger.child({ module });
};