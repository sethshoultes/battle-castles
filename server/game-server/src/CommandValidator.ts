import {
  GameCommand,
  DeployUnitCommand,
  GameState,
  Player,
  TeamSide,
  ValidationResult,
  CommandType,
  Vector2
} from './types';
import { GAME_CONFIG, UNIT_STATS } from './config';
import { createLogger } from './logger';

const logger = createLogger('CommandValidator');

export class CommandValidator {
  /**
   * Validates a game command from a player
   */
  static validateCommand(
    command: GameCommand,
    player: Player,
    gameState: GameState
  ): ValidationResult {
    // Check if game is active
    if (!gameState.isActive) {
      return {
        valid: false,
        error: 'Game is not active'
      };
    }

    // Check if player exists and is connected
    if (!player || !player.isConnected) {
      return {
        valid: false,
        error: 'Player is not connected'
      };
    }

    // Validate timestamp (prevent replay attacks)
    const currentTime = Date.now();
    if (Math.abs(command.timestamp - currentTime) > 5000) {
      logger.warn('Command timestamp validation failed', {
        playerId: player.id,
        commandTime: command.timestamp,
        serverTime: currentTime,
        difference: Math.abs(command.timestamp - currentTime)
      });
      return {
        valid: false,
        error: 'Command timestamp is invalid'
      };
    }

    // Validate specific command types
    switch (command.type) {
      case CommandType.DEPLOY_UNIT:
        return this.validateDeployUnit(command, player, gameState);

      case CommandType.CAST_SPELL:
        return this.validateCastSpell(command, player, gameState);

      case CommandType.SURRENDER:
        return { valid: true };

      default:
        return {
          valid: false,
          error: 'Unknown command type'
        };
    }
  }

  /**
   * Validates unit deployment command
   */
  private static validateDeployUnit(
    command: DeployUnitCommand,
    player: Player,
    gameState: GameState
  ): ValidationResult {
    // Check if unit type exists
    const unitStats = UNIT_STATS[command.unitType];
    if (!unitStats) {
      return {
        valid: false,
        error: 'Invalid unit type'
      };
    }

    // Check elixir cost
    if (player.elixir < unitStats.elixirCost) {
      return {
        valid: false,
        error: `Insufficient elixir. Need ${unitStats.elixirCost}, have ${player.elixir.toFixed(1)}`
      };
    }

    // Validate deployment position
    const positionValidation = this.validateDeploymentPosition(
      command.position,
      player.team
    );
    if (!positionValidation.valid) {
      return positionValidation;
    }

    // Check for unit overlap (can't deploy on top of existing units)
    const overlappingUnit = this.checkUnitOverlap(command.position, gameState);
    if (overlappingUnit) {
      return {
        valid: false,
        error: 'Cannot deploy unit on top of existing unit'
      };
    }

    return { valid: true };
  }

  /**
   * Validates spell casting command
   */
  private static validateCastSpell(
    command: any,
    player: Player,
    gameState: GameState
  ): ValidationResult {
    // TODO: Implement spell validation when spell system is added
    return {
      valid: false,
      error: 'Spell system not yet implemented'
    };
  }

  /**
   * Validates deployment position based on team and deployment zones
   */
  private static validateDeploymentPosition(
    position: Vector2,
    team: TeamSide
  ): ValidationResult {
    // Check if position is within map bounds
    if (
      position.x < 0 ||
      position.x > GAME_CONFIG.mapWidth ||
      position.y < 0 ||
      position.y > GAME_CONFIG.mapHeight
    ) {
      return {
        valid: false,
        error: 'Position is out of map bounds'
      };
    }

    // Check deployment zone based on team
    const deploymentZoneStart = team === TeamSide.LEFT ? 0 : GAME_CONFIG.mapWidth - GAME_CONFIG.deploymentZoneDepth;
    const deploymentZoneEnd = team === TeamSide.LEFT ? GAME_CONFIG.deploymentZoneDepth : GAME_CONFIG.mapWidth;

    if (position.x < deploymentZoneStart || position.x > deploymentZoneEnd) {
      return {
        valid: false,
        error: 'Position is outside deployment zone'
      };
    }

    // Additional validation: Can't deploy in enemy's last row (anti-cheese)
    const enemyLastRow = team === TeamSide.LEFT ? GAME_CONFIG.mapWidth - 1 : 0;
    if (Math.abs(position.x - enemyLastRow) < 1) {
      return {
        valid: false,
        error: 'Cannot deploy units at enemy base line'
      };
    }

    return { valid: true };
  }

  /**
   * Checks if a unit would overlap with existing units
   */
  private static checkUnitOverlap(
    position: Vector2,
    gameState: GameState
  ): boolean {
    const OVERLAP_THRESHOLD = 0.5; // Units can't be within 0.5 units of each other

    for (const unit of gameState.units.values()) {
      if (!unit.isAlive) continue;

      const distance = Math.sqrt(
        Math.pow(position.x - unit.position.x, 2) +
        Math.pow(position.y - unit.position.y, 2)
      );

      if (distance < OVERLAP_THRESHOLD) {
        return true;
      }
    }

    return false;
  }

  /**
   * Validates player state for anti-cheat
   */
  static validatePlayerState(
    player: Player,
    expectedElixir: number,
    tolerance: number = 0.1
  ): boolean {
    // Check if player's reported elixir matches server calculation
    if (Math.abs(player.elixir - expectedElixir) > tolerance) {
      logger.warn('Player elixir mismatch detected', {
        playerId: player.id,
        reportedElixir: player.elixir,
        expectedElixir,
        difference: Math.abs(player.elixir - expectedElixir)
      });
      return false;
    }

    return true;
  }

  /**
   * Performs rate limiting check for commands
   */
  private static commandHistory = new Map<string, number[]>();

  static checkRateLimit(playerId: string, maxCommandsPerSecond: number = 10): boolean {
    const now = Date.now();
    const history = this.commandHistory.get(playerId) || [];

    // Remove commands older than 1 second
    const recentCommands = history.filter(time => now - time < 1000);

    if (recentCommands.length >= maxCommandsPerSecond) {
      logger.warn('Rate limit exceeded', {
        playerId,
        commandCount: recentCommands.length,
        limit: maxCommandsPerSecond
      });
      return false;
    }

    recentCommands.push(now);
    this.commandHistory.set(playerId, recentCommands);
    return true;
  }

  /**
   * Cleans up old command history
   */
  static cleanupCommandHistory(): void {
    const now = Date.now();
    for (const [playerId, history] of this.commandHistory.entries()) {
      const recentCommands = history.filter(time => now - time < 5000);
      if (recentCommands.length === 0) {
        this.commandHistory.delete(playerId);
      } else {
        this.commandHistory.set(playerId, recentCommands);
      }
    }
  }
}