import express from 'express';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import dotenv from 'dotenv';
import { MatchmakingQueue } from './MatchmakingQueue';
import { SocketEvent } from './types';
import { SERVER_CONFIG } from './config';
import { logger } from './logger';

// Load environment variables
dotenv.config();

// Create Express app
const app = express();
const httpServer = createServer(app);

// Create Socket.IO server with CORS configuration
const io = new SocketIOServer(httpServer, {
  cors: {
    origin: SERVER_CONFIG.CORS_ORIGIN,
    methods: ['GET', 'POST'],
    credentials: true
  },
  pingTimeout: 10000,
  pingInterval: 5000
});

// Middleware
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  const stats = matchmakingQueue.getStats();
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: Date.now(),
    ...stats
  });
});

// Game server info endpoint
app.get('/info', (req, res) => {
  res.json({
    name: 'Battle Castles Game Server',
    version: '1.0.0',
    tickRate: 20,
    maxPlayers: 2,
    port: SERVER_CONFIG.PORT
  });
});

// Initialize matchmaking queue
const matchmakingQueue = new MatchmakingQueue();

// Handle socket connections
io.on('connection', (socket) => {
  logger.info('Client connected', {
    socketId: socket.id,
    address: socket.handshake.address
  });

  // Handle joining matchmaking queue
  socket.on(SocketEvent.JOIN_QUEUE, (data: { playerName: string }) => {
    try {
      const playerName = data.playerName || 'Anonymous';
      matchmakingQueue.addToQueue(socket, playerName);
    } catch (error) {
      logger.error('Error joining queue', { error, socketId: socket.id });
      socket.emit(SocketEvent.ERROR, {
        message: 'Failed to join queue',
        code: 'JOIN_QUEUE_ERROR'
      });
    }
  });

  // Handle leaving matchmaking queue
  socket.on(SocketEvent.LEAVE_QUEUE, () => {
    try {
      matchmakingQueue.removeFromQueue(socket.id);
    } catch (error) {
      logger.error('Error leaving queue', { error, socketId: socket.id });
    }
  });

  // Handle disconnect
  socket.on('disconnect', (reason) => {
    logger.info('Client disconnected', {
      socketId: socket.id,
      reason
    });
    matchmakingQueue.handleDisconnect(socket.id);
  });

  // Handle errors
  socket.on('error', (error) => {
    logger.error('Socket error', {
      socketId: socket.id,
      error
    });
  });
});

// Error handling for uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught exception', { error });
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled rejection', { reason, promise });
});

// Graceful shutdown
const shutdown = () => {
  logger.info('Shutting down server...');

  // Stop accepting new connections
  httpServer.close(() => {
    logger.info('HTTP server closed');
  });

  // Close all socket connections
  io.close(() => {
    logger.info('Socket.IO server closed');
  });

  // Shutdown matchmaking queue
  matchmakingQueue.shutdown();

  // Exit after a timeout
  setTimeout(() => {
    logger.warn('Forced shutdown after timeout');
    process.exit(0);
  }, 10000);
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

// Start the server
const PORT = SERVER_CONFIG.PORT;
httpServer.listen(PORT, () => {
  logger.info('Game server started', {
    port: PORT,
    environment: process.env.NODE_ENV || 'development',
    corsOrigin: SERVER_CONFIG.CORS_ORIGIN,
    logLevel: SERVER_CONFIG.LOG_LEVEL
  });
});