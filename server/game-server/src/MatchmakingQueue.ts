import { Socket } from 'socket.io';
import { v4 as uuidv4 } from 'uuid';
import { GameRoom } from './GameRoom';
import { SocketEvent } from './types';
import { SERVER_CONFIG } from './config';
import { createLogger } from './logger';

const logger = createLogger('MatchmakingQueue');

interface QueuedPlayer {
  socket: Socket;
  playerName: string;
  joinedAt: number;
}

export class MatchmakingQueue {
  private queue: Map<string, QueuedPlayer> = new Map();
  private rooms: Map<string, GameRoom> = new Map();
  private socketToPlayerId: Map<string, string> = new Map();
  private cleanupInterval: NodeJS.Timeout;

  constructor() {
    // Periodically clean up empty rooms and timed-out queue entries
    this.cleanupInterval = setInterval(() => {
      this.cleanup();
    }, SERVER_CONFIG.ROOM_CLEANUP_INTERVAL);
  }

  /**
   * Add a player to the matchmaking queue
   */
  addToQueue(socket: Socket, playerName: string): void {
    const playerId = uuidv4();

    // Remove player from queue if already queued
    this.removeFromQueue(socket.id);

    // Add to queue
    this.queue.set(playerId, {
      socket,
      playerName,
      joinedAt: Date.now()
    });

    this.socketToPlayerId.set(socket.id, playerId);

    // Notify player they joined the queue
    socket.emit(SocketEvent.QUEUE_JOINED, {
      playerId,
      queuePosition: this.queue.size
    });

    logger.info('Player joined queue', {
      playerId,
      playerName,
      queueSize: this.queue.size
    });

    // Try to match players
    this.attemptMatch();
  }

  /**
   * Remove a player from the queue
   */
  removeFromQueue(socketId: string): void {
    const playerId = this.socketToPlayerId.get(socketId);
    if (!playerId) return;

    const queuedPlayer = this.queue.get(playerId);
    if (queuedPlayer) {
      this.queue.delete(playerId);
      this.socketToPlayerId.delete(socketId);

      queuedPlayer.socket.emit(SocketEvent.QUEUE_LEFT);

      logger.info('Player left queue', {
        playerId,
        queueSize: this.queue.size
      });
    }
  }

  /**
   * Attempt to match players
   */
  private attemptMatch(): void {
    if (this.queue.size < 2) return;

    // Get the first two players in queue (FIFO)
    const players = Array.from(this.queue.entries()).slice(0, 2);
    const [[player1Id, player1], [player2Id, player2]] = players;

    // Check if players have been waiting too long
    const now = Date.now();
    if (now - player1.joinedAt > SERVER_CONFIG.MATCHMAKING_TIMEOUT) {
      this.handleMatchmakingTimeout(player1Id, player1);
      return;
    }
    if (now - player2.joinedAt > SERVER_CONFIG.MATCHMAKING_TIMEOUT) {
      this.handleMatchmakingTimeout(player2Id, player2);
      return;
    }

    // Remove players from queue
    this.queue.delete(player1Id);
    this.queue.delete(player2Id);
    this.socketToPlayerId.delete(player1.socket.id);
    this.socketToPlayerId.delete(player2.socket.id);

    // Create a new room
    const roomId = uuidv4();
    const room = new GameRoom(roomId);

    // Add players to room
    const success1 = room.addPlayer(player1.socket, player1.playerName);
    const success2 = room.addPlayer(player2.socket, player2.playerName);

    if (success1 && success2) {
      this.rooms.set(roomId, room);

      logger.info('Match created', {
        roomId,
        player1: { id: player1Id, name: player1.playerName },
        player2: { id: player2Id, name: player2.playerName }
      });
    } else {
      // If room creation failed, put players back in queue
      logger.error('Failed to create match', { roomId });
      this.addToQueue(player1.socket, player1.playerName);
      this.addToQueue(player2.socket, player2.playerName);
    }
  }

  /**
   * Handle matchmaking timeout
   */
  private handleMatchmakingTimeout(playerId: string, player: QueuedPlayer): void {
    this.queue.delete(playerId);
    this.socketToPlayerId.delete(player.socket.id);

    player.socket.emit(SocketEvent.ERROR, {
      message: 'Matchmaking timeout - no opponent found',
      code: 'MATCHMAKING_TIMEOUT'
    });

    logger.warn('Matchmaking timeout', {
      playerId,
      playerName: player.playerName,
      waitTime: Date.now() - player.joinedAt
    });
  }

  /**
   * Handle player disconnect
   */
  handleDisconnect(socketId: string): void {
    // Remove from queue if queued
    this.removeFromQueue(socketId);

    // Note: GameRoom handles disconnects for players in games
    logger.debug('Socket disconnected', { socketId });
  }

  /**
   * Clean up empty rooms and timed-out queue entries
   */
  private cleanup(): void {
    const now = Date.now();

    // Clean up timed-out queue entries
    for (const [playerId, player] of this.queue.entries()) {
      if (now - player.joinedAt > SERVER_CONFIG.MATCHMAKING_TIMEOUT) {
        this.handleMatchmakingTimeout(playerId, player);
      }
    }

    // Clean up empty rooms
    for (const [roomId, room] of this.rooms.entries()) {
      if (room.isEmpty()) {
        room.cleanup();
        this.rooms.delete(roomId);
        logger.info('Empty room cleaned up', { roomId });
      }
    }

    // Clean up command history
    CommandValidator.cleanupCommandHistory();

    logger.debug('Cleanup completed', {
      queueSize: this.queue.size,
      roomCount: this.rooms.size,
      maxRooms: SERVER_CONFIG.MAX_ROOMS
    });
  }

  /**
   * Get statistics
   */
  getStats(): any {
    return {
      queueSize: this.queue.size,
      activeRooms: this.rooms.size,
      roomsInfo: Array.from(this.rooms.values()).map(room => room.getRoomInfo())
    };
  }

  /**
   * Shutdown the matchmaking system
   */
  shutdown(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }

    // Clean up all rooms
    for (const room of this.rooms.values()) {
      room.cleanup();
    }

    this.queue.clear();
    this.rooms.clear();
    this.socketToPlayerId.clear();

    logger.info('Matchmaking queue shut down');
  }
}

// Import CommandValidator to use its cleanup method
import { CommandValidator } from './CommandValidator';