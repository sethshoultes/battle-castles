import { v4 as uuidv4 } from 'uuid';
import { Socket } from 'socket.io';
import {
  Player,
  GameCommand,
  TeamSide,
  DeployUnitCommand,
  Unit,
  UnitType,
  CommandType,
  SocketEvent,
  GameEndedPayload
} from './types';
import { BattleState } from './BattleState';
import { CommandValidator } from './CommandValidator';
import { GAME_CONFIG, UNIT_STATS } from './config';
import { createLogger } from './logger';

const logger = createLogger('GameRoom');

export class GameRoom {
  private roomId: string;
  private battleState: BattleState;
  private players: Map<string, Player>;
  private sockets: Map<string, Socket>;
  private tickInterval: NodeJS.Timeout | null = null;
  private lastTickTime: number = Date.now();
  private commandQueue: Array<{ playerId: string; command: GameCommand }> = [];
  private isRunning: boolean = false;

  constructor(roomId: string) {
    this.roomId = roomId;
    this.battleState = new BattleState(roomId);
    this.players = new Map();
    this.sockets = new Map();
  }

  /**
   * Add a player to the room
   */
  addPlayer(socket: Socket, playerName: string): boolean {
    if (this.players.size >= 2) {
      logger.warn('Room is full', { roomId: this.roomId });
      return false;
    }

    const playerId = uuidv4();
    const team = this.players.size === 0 ? TeamSide.LEFT : TeamSide.RIGHT;

    const player: Player = {
      id: playerId,
      socketId: socket.id,
      name: playerName,
      team,
      elixir: GAME_CONFIG.initialElixir,
      maxElixir: GAME_CONFIG.maxElixir,
      elixirRegenRate: GAME_CONFIG.elixirRegenRate,
      lastElixirUpdate: Date.now(),
      isConnected: true,
      crowns: 0
    };

    this.players.set(playerId, player);
    this.sockets.set(playerId, socket);
    this.battleState.addPlayer(player);

    // Set up socket event handlers
    this.setupSocketHandlers(socket, playerId);

    logger.info('Player joined room', {
      roomId: this.roomId,
      playerId,
      playerName,
      team,
      playerCount: this.players.size
    });

    // Notify player they joined
    socket.emit(SocketEvent.GAME_FOUND, {
      roomId: this.roomId,
      playerId,
      team,
      opponent: this.getOpponent(playerId)
    });

    // Start game if room is full
    if (this.players.size === 2) {
      this.startGame();
    }

    return true;
  }

  /**
   * Set up socket event handlers for a player
   */
  private setupSocketHandlers(socket: Socket, playerId: string): void {
    // Handle game commands
    socket.on(SocketEvent.GAME_COMMAND, (command: GameCommand) => {
      this.handleGameCommand(playerId, command);
    });

    // Handle disconnect
    socket.on('disconnect', () => {
      this.handlePlayerDisconnect(playerId);
    });

    // Handle ping for latency measurement
    socket.on(SocketEvent.PING, (timestamp: number) => {
      socket.emit(SocketEvent.PONG, timestamp);
    });
  }

  /**
   * Handle game command from player
   */
  private handleGameCommand(playerId: string, command: GameCommand): void {
    const player = this.players.get(playerId);
    if (!player) {
      logger.error('Player not found for command', { playerId, command });
      return;
    }

    // Check rate limiting
    if (!CommandValidator.checkRateLimit(playerId)) {
      const socket = this.sockets.get(playerId);
      if (socket) {
        socket.emit(SocketEvent.ERROR, {
          message: 'Command rate limit exceeded',
          code: 'RATE_LIMIT'
        });
      }
      return;
    }

    // Validate command
    const validation = CommandValidator.validateCommand(
      command,
      player,
      this.battleState.getState()
    );

    if (!validation.valid) {
      logger.warn('Invalid command', {
        playerId,
        command,
        error: validation.error
      });

      const socket = this.sockets.get(playerId);
      if (socket) {
        socket.emit(SocketEvent.ERROR, {
          message: validation.error,
          code: 'INVALID_COMMAND'
        });
      }
      return;
    }

    // Add command to queue for processing in next tick
    this.commandQueue.push({ playerId, command });

    logger.debug('Command queued', {
      playerId,
      commandType: command.type,
      queueSize: this.commandQueue.length
    });
  }

  /**
   * Process queued commands
   */
  private processCommandQueue(): void {
    while (this.commandQueue.length > 0) {
      const { playerId, command } = this.commandQueue.shift()!;
      const player = this.players.get(playerId);

      if (!player) continue;

      switch (command.type) {
        case CommandType.DEPLOY_UNIT:
          this.handleDeployUnit(player, command as DeployUnitCommand);
          break;

        case CommandType.SURRENDER:
          this.handleSurrender(player);
          break;

        // Add other command types as needed
      }
    }
  }

  /**
   * Handle unit deployment
   */
  private handleDeployUnit(player: Player, command: DeployUnitCommand): void {
    const unitStats = UNIT_STATS[command.unitType];

    // Deduct elixir
    player.elixir -= unitStats.elixirCost;

    // Create unit
    const unit: Unit = {
      id: uuidv4(),
      type: command.unitType,
      team: player.team,
      position: { ...command.position },
      health: unitStats.health,
      maxHealth: unitStats.maxHealth,
      target: null,
      lastAttackTime: 0,
      stats: {
        ...unitStats,
        type: command.unitType
      },
      isAlive: true,
      deployedAt: Date.now()
    };

    this.battleState.addUnit(unit);

    logger.info('Unit deployed', {
      playerId: player.id,
      unitId: unit.id,
      unitType: command.unitType,
      position: command.position,
      elixirCost: unitStats.elixirCost,
      remainingElixir: player.elixir
    });
  }

  /**
   * Handle player surrender
   */
  private handleSurrender(player: Player): void {
    const winner = player.team === TeamSide.LEFT ? TeamSide.RIGHT : TeamSide.LEFT;
    this.endGame(winner, 'surrender');
  }

  /**
   * Handle player disconnect
   */
  private handlePlayerDisconnect(playerId: string): void {
    const player = this.players.get(playerId);
    if (!player) return;

    player.isConnected = false;
    this.battleState.removePlayer(playerId);

    logger.info('Player disconnected', {
      roomId: this.roomId,
      playerId,
      playerName: player.name
    });

    // End game if player disconnects
    if (this.isRunning) {
      const winner = player.team === TeamSide.LEFT ? TeamSide.RIGHT : TeamSide.LEFT;
      this.endGame(winner, 'disconnect');
    }
  }

  /**
   * Start the game
   */
  private startGame(): void {
    if (this.isRunning) return;

    this.isRunning = true;
    this.battleState.startGame();
    this.lastTickTime = Date.now();

    // Start game loop at configured tick rate
    const tickDelay = 1000 / GAME_CONFIG.tickRate;
    this.tickInterval = setInterval(() => this.gameTick(), tickDelay);

    // Notify all players
    this.broadcast(SocketEvent.GAME_STATE_UPDATE, this.getGameStateForClients());

    logger.info('Game started', {
      roomId: this.roomId,
      tickRate: GAME_CONFIG.tickRate,
      players: Array.from(this.players.values()).map(p => ({
        id: p.id,
        name: p.name,
        team: p.team
      }))
    });
  }

  /**
   * Game tick - main update loop
   */
  private gameTick(): void {
    if (!this.isRunning) return;

    const currentTime = Date.now();
    const deltaTime = currentTime - this.lastTickTime;
    this.lastTickTime = currentTime;

    // Process command queue
    this.processCommandQueue();

    // Update game state
    this.battleState.update(deltaTime);

    // Check if game ended
    if (!this.battleState.isActive()) {
      const winner = this.battleState.getWinner();
      if (winner) {
        this.endGame(winner, 'towers_destroyed');
      }
      return;
    }

    // Send state updates to all players
    this.sendStateUpdates();
  }

  /**
   * Send state updates to all players
   */
  private sendStateUpdates(): void {
    const gameStates = this.getGameStateForClients();

    for (const [playerId, socket] of this.sockets.entries()) {
      const playerState = gameStates.get(playerId);
      if (playerState) {
        socket.emit(SocketEvent.GAME_STATE_UPDATE, playerState);
      }
    }
  }

  /**
   * Get game state for all clients
   */
  private getGameStateForClients(): Map<string, any> {
    const states = new Map();

    for (const playerId of this.players.keys()) {
      try {
        states.set(playerId, this.battleState.serialize(playerId));
      } catch (error) {
        logger.error('Failed to serialize game state', { playerId, error });
      }
    }

    return states;
  }

  /**
   * End the game
   */
  private endGame(winner: TeamSide, reason: 'towers_destroyed' | 'time_limit' | 'surrender' | 'disconnect'): void {
    if (!this.isRunning) return;

    this.isRunning = false;

    // Stop game loop
    if (this.tickInterval) {
      clearInterval(this.tickInterval);
      this.tickInterval = null;
    }

    // Get final state for each player
    const finalStates = this.getGameStateForClients();

    // Notify all players
    for (const [playerId, socket] of this.sockets.entries()) {
      const finalState = finalStates.get(playerId);
      const payload: GameEndedPayload = {
        winner,
        reason,
        finalState
      };
      socket.emit(SocketEvent.GAME_ENDED, payload);
    }

    logger.info('Game ended', {
      roomId: this.roomId,
      winner,
      reason,
      duration: Date.now() - this.battleState.getState().startTime
    });
  }

  /**
   * Broadcast event to all connected players
   */
  private broadcast(event: string, data: any): void {
    for (const socket of this.sockets.values()) {
      socket.emit(event, data);
    }
  }

  /**
   * Get opponent info for a player
   */
  private getOpponent(playerId: string): any {
    for (const [id, player] of this.players.entries()) {
      if (id !== playerId) {
        return {
          id: player.id,
          name: player.name,
          team: player.team
        };
      }
    }
    return null;
  }

  /**
   * Clean up the room
   */
  cleanup(): void {
    if (this.tickInterval) {
      clearInterval(this.tickInterval);
    }

    for (const socket of this.sockets.values()) {
      socket.removeAllListeners();
    }

    this.players.clear();
    this.sockets.clear();
    this.commandQueue = [];

    logger.info('Room cleaned up', { roomId: this.roomId });
  }

  /**
   * Get room info
   */
  getRoomInfo(): any {
    return {
      roomId: this.roomId,
      playerCount: this.players.size,
      isRunning: this.isRunning,
      players: Array.from(this.players.values()).map(p => ({
        id: p.id,
        name: p.name,
        team: p.team,
        isConnected: p.isConnected
      }))
    };
  }

  /**
   * Check if room is empty
   */
  isEmpty(): boolean {
    return this.players.size === 0;
  }

  /**
   * Check if room is full
   */
  isFull(): boolean {
    return this.players.size >= 2;
  }

  /**
   * Get room ID
   */
  getRoomId(): string {
    return this.roomId;
  }
}