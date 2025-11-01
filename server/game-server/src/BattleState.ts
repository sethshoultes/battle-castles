import { v4 as uuidv4 } from 'uuid';
import {
  GameState,
  Player,
  Unit,
  Tower,
  TeamSide,
  TowerType,
  ClientGameState,
  Vector2
} from './types';
import { TOWER_CONFIG, GAME_CONFIG } from './config';
import { createLogger } from './logger';

const logger = createLogger('BattleState');

export class BattleState {
  private gameState: GameState;

  constructor(roomId: string) {
    this.gameState = {
      roomId,
      players: new Map(),
      units: new Map(),
      towers: new Map(),
      gameTime: 0,
      startTime: Date.now(),
      isActive: false,
      winner: null,
      lastUpdateTime: Date.now()
    };

    this.initializeTowers();
  }

  /**
   * Initialize towers for both teams
   */
  private initializeTowers(): void {
    // Left team towers
    this.createTower(TowerType.MAIN, TeamSide.LEFT, { x: 2, y: GAME_CONFIG.mapHeight / 2 });
    this.createTower(TowerType.LEFT, TeamSide.LEFT, { x: 4, y: GAME_CONFIG.mapHeight / 4 });
    this.createTower(TowerType.RIGHT, TeamSide.LEFT, { x: 4, y: (3 * GAME_CONFIG.mapHeight) / 4 });

    // Right team towers
    this.createTower(TowerType.MAIN, TeamSide.RIGHT, { x: GAME_CONFIG.mapWidth - 2, y: GAME_CONFIG.mapHeight / 2 });
    this.createTower(TowerType.LEFT, TeamSide.RIGHT, { x: GAME_CONFIG.mapWidth - 4, y: GAME_CONFIG.mapHeight / 4 });
    this.createTower(TowerType.RIGHT, TeamSide.RIGHT, { x: GAME_CONFIG.mapWidth - 4, y: (3 * GAME_CONFIG.mapHeight) / 4 });
  }

  /**
   * Create a tower
   */
  private createTower(type: TowerType, team: TeamSide, position: Vector2): void {
    const config = type === TowerType.MAIN ? TOWER_CONFIG.MAIN_TOWER : TOWER_CONFIG.SIDE_TOWER;
    const tower: Tower = {
      id: `tower_${team}_${type}`,
      type,
      team,
      position,
      health: config.health,
      maxHealth: config.maxHealth,
      damage: config.damage,
      attackSpeed: config.attackSpeed,
      attackRange: config.attackRange,
      lastAttackTime: 0,
      isDestroyed: false
    };
    this.gameState.towers.set(tower.id, tower);
  }

  /**
   * Add a player to the game
   */
  addPlayer(player: Player): void {
    this.gameState.players.set(player.id, player);
    logger.info('Player added to game', {
      playerId: player.id,
      team: player.team,
      roomId: this.gameState.roomId
    });
  }

  /**
   * Remove a player from the game
   */
  removePlayer(playerId: string): void {
    const player = this.gameState.players.get(playerId);
    if (player) {
      player.isConnected = false;
      logger.info('Player disconnected', {
        playerId,
        roomId: this.gameState.roomId
      });
    }
  }

  /**
   * Start the game
   */
  startGame(): void {
    this.gameState.isActive = true;
    this.gameState.startTime = Date.now();
    this.gameState.lastUpdateTime = Date.now();
    logger.info('Game started', { roomId: this.gameState.roomId });
  }

  /**
   * Update game state (called every tick)
   */
  update(deltaTime: number): void {
    if (!this.gameState.isActive) return;

    // Update game time
    this.gameState.gameTime += deltaTime;
    this.gameState.lastUpdateTime = Date.now();

    // Update elixir for all players
    this.updatePlayersElixir(deltaTime);

    // Update units
    this.updateUnits(deltaTime);

    // Update towers
    this.updateTowers(deltaTime);

    // Check win conditions
    this.checkWinConditions();
  }

  /**
   * Update elixir regeneration for all players
   */
  private updatePlayersElixir(deltaTime: number): void {
    const elixirMultiplier = this.gameState.gameTime >= GAME_CONFIG.doubleElixirTime ? 2 : 1;

    for (const player of this.gameState.players.values()) {
      if (!player.isConnected) continue;

      const elixirGain = (player.elixirRegenRate * elixirMultiplier * deltaTime) / 1000;
      player.elixir = Math.min(player.elixir + elixirGain, player.maxElixir);
      player.lastElixirUpdate = Date.now();
    }
  }

  /**
   * Update all units
   */
  private updateUnits(deltaTime: number): void {
    for (const unit of this.gameState.units.values()) {
      if (!unit.isAlive) continue;

      // Find target
      if (!unit.target) {
        unit.target = this.findTarget(unit);
      }

      // Move towards target or attack
      if (unit.target) {
        const target = this.getTargetEntity(unit.target);
        if (target) {
          const distance = this.calculateDistance(unit.position, target.position);

          if (distance <= unit.stats.attackRange) {
            // Attack
            this.performAttack(unit, target, deltaTime);
          } else {
            // Move towards target
            this.moveUnit(unit, target.position, deltaTime);
          }
        } else {
          unit.target = null;
        }
      }

      // Check if unit is dead
      if (unit.health <= 0) {
        unit.isAlive = false;
        logger.debug('Unit destroyed', {
          unitId: unit.id,
          type: unit.type,
          team: unit.team
        });
      }
    }

    // Clean up dead units
    this.cleanupDeadUnits();
  }

  /**
   * Update all towers
   */
  private updateTowers(deltaTime: number): void {
    for (const tower of this.gameState.towers.values()) {
      if (tower.isDestroyed) continue;

      // Find nearest enemy unit to attack
      const target = this.findTowerTarget(tower);
      if (target) {
        const currentTime = Date.now();
        const attackDelay = 1000 / tower.attackSpeed;

        if (currentTime - tower.lastAttackTime >= attackDelay) {
          target.health -= tower.damage;
          tower.lastAttackTime = currentTime;

          logger.debug('Tower attacked unit', {
            towerId: tower.id,
            targetId: target.id,
            damage: tower.damage
          });
        }
      }

      // Check if tower is destroyed
      if (tower.health <= 0 && !tower.isDestroyed) {
        tower.isDestroyed = true;
        const player = this.getPlayerByTeam(tower.team === TeamSide.LEFT ? TeamSide.RIGHT : TeamSide.LEFT);
        if (player) {
          player.crowns++;
        }
        logger.info('Tower destroyed', {
          towerId: tower.id,
          team: tower.team,
          type: tower.type
        });
      }
    }
  }

  /**
   * Find a target for a unit
   */
  private findTarget(unit: Unit): string | null {
    let nearestTarget: { id: string; distance: number } | null = null;
    const enemyTeam = unit.team === TeamSide.LEFT ? TeamSide.RIGHT : TeamSide.LEFT;

    // Check enemy units
    for (const enemyUnit of this.gameState.units.values()) {
      if (enemyUnit.team === enemyTeam && enemyUnit.isAlive) {
        const distance = this.calculateDistance(unit.position, enemyUnit.position);
        if (!nearestTarget || distance < nearestTarget.distance) {
          nearestTarget = { id: enemyUnit.id, distance };
        }
      }
    }

    // Check enemy towers
    for (const tower of this.gameState.towers.values()) {
      if (tower.team === enemyTeam && !tower.isDestroyed) {
        const distance = this.calculateDistance(unit.position, tower.position);
        if (!nearestTarget || distance < nearestTarget.distance) {
          nearestTarget = { id: tower.id, distance };
        }
      }
    }

    return nearestTarget?.id || null;
  }

  /**
   * Find target for a tower
   */
  private findTowerTarget(tower: Tower): Unit | null {
    const enemyTeam = tower.team === TeamSide.LEFT ? TeamSide.RIGHT : TeamSide.LEFT;
    let nearestUnit: Unit | null = null;
    let nearestDistance = Infinity;

    for (const unit of this.gameState.units.values()) {
      if (unit.team === enemyTeam && unit.isAlive) {
        const distance = this.calculateDistance(tower.position, unit.position);
        if (distance <= tower.attackRange && distance < nearestDistance) {
          nearestUnit = unit;
          nearestDistance = distance;
        }
      }
    }

    return nearestUnit;
  }

  /**
   * Get target entity (unit or tower)
   */
  private getTargetEntity(targetId: string): { position: Vector2; health: number } | null {
    const unit = this.gameState.units.get(targetId);
    if (unit && unit.isAlive) {
      return unit;
    }

    const tower = this.gameState.towers.get(targetId);
    if (tower && !tower.isDestroyed) {
      return tower;
    }

    return null;
  }

  /**
   * Perform attack
   */
  private performAttack(attacker: Unit, target: any, deltaTime: number): void {
    const currentTime = Date.now();
    const attackDelay = 1000 / attacker.stats.attackSpeed;

    if (currentTime - attacker.lastAttackTime >= attackDelay) {
      target.health -= attacker.stats.damage;
      attacker.lastAttackTime = currentTime;

      logger.debug('Unit attacked', {
        attackerId: attacker.id,
        targetId: target.id || 'tower',
        damage: attacker.stats.damage
      });
    }
  }

  /**
   * Move unit towards a position
   */
  private moveUnit(unit: Unit, targetPos: Vector2, deltaTime: number): void {
    const dx = targetPos.x - unit.position.x;
    const dy = targetPos.y - unit.position.y;
    const distance = Math.sqrt(dx * dx + dy * dy);

    if (distance > 0) {
      const moveDistance = (unit.stats.moveSpeed * deltaTime) / 1000;
      const moveRatio = Math.min(moveDistance / distance, 1);

      unit.position.x += dx * moveRatio;
      unit.position.y += dy * moveRatio;
    }
  }

  /**
   * Calculate distance between two positions
   */
  private calculateDistance(pos1: Vector2, pos2: Vector2): number {
    return Math.sqrt(
      Math.pow(pos2.x - pos1.x, 2) + Math.pow(pos2.y - pos1.y, 2)
    );
  }

  /**
   * Clean up dead units
   */
  private cleanupDeadUnits(): void {
    const deadUnits: string[] = [];
    for (const [id, unit] of this.gameState.units.entries()) {
      if (!unit.isAlive) {
        deadUnits.push(id);
      }
    }
    deadUnits.forEach(id => this.gameState.units.delete(id));
  }

  /**
   * Check win conditions
   */
  private checkWinConditions(): void {
    // Check if all main towers of a team are destroyed
    const leftMainTower = Array.from(this.gameState.towers.values()).find(
      t => t.team === TeamSide.LEFT && t.type === TowerType.MAIN
    );
    const rightMainTower = Array.from(this.gameState.towers.values()).find(
      t => t.team === TeamSide.RIGHT && t.type === TowerType.MAIN
    );

    if (leftMainTower?.isDestroyed) {
      this.endGame(TeamSide.RIGHT);
    } else if (rightMainTower?.isDestroyed) {
      this.endGame(TeamSide.LEFT);
    }

    // Check time limit
    if (this.gameState.gameTime >= GAME_CONFIG.maxGameTime) {
      // Determine winner by crowns or tower health
      const leftPlayer = this.getPlayerByTeam(TeamSide.LEFT);
      const rightPlayer = this.getPlayerByTeam(TeamSide.RIGHT);

      if (leftPlayer && rightPlayer) {
        if (leftPlayer.crowns > rightPlayer.crowns) {
          this.endGame(TeamSide.LEFT);
        } else if (rightPlayer.crowns > leftPlayer.crowns) {
          this.endGame(TeamSide.RIGHT);
        } else {
          // Tie - check total tower health
          const leftHealth = this.getTotalTowerHealth(TeamSide.LEFT);
          const rightHealth = this.getTotalTowerHealth(TeamSide.RIGHT);
          this.endGame(leftHealth > rightHealth ? TeamSide.LEFT : TeamSide.RIGHT);
        }
      }
    }
  }

  /**
   * Get player by team
   */
  private getPlayerByTeam(team: TeamSide): Player | null {
    for (const player of this.gameState.players.values()) {
      if (player.team === team) {
        return player;
      }
    }
    return null;
  }

  /**
   * Get total tower health for a team
   */
  private getTotalTowerHealth(team: TeamSide): number {
    let totalHealth = 0;
    for (const tower of this.gameState.towers.values()) {
      if (tower.team === team && !tower.isDestroyed) {
        totalHealth += tower.health;
      }
    }
    return totalHealth;
  }

  /**
   * End the game
   */
  private endGame(winner: TeamSide): void {
    this.gameState.isActive = false;
    this.gameState.winner = winner;
    logger.info('Game ended', {
      roomId: this.gameState.roomId,
      winner,
      gameTime: this.gameState.gameTime
    });
  }

  /**
   * Add a unit to the game
   */
  addUnit(unit: Unit): void {
    this.gameState.units.set(unit.id, unit);
  }

  /**
   * Serialize game state for client
   */
  serialize(playerId: string): ClientGameState {
    const player = this.gameState.players.get(playerId);
    if (!player) {
      throw new Error('Player not found');
    }

    return {
      roomId: this.gameState.roomId,
      players: Array.from(this.gameState.players.values()),
      units: Array.from(this.gameState.units.values()),
      towers: Array.from(this.gameState.towers.values()),
      gameTime: this.gameState.gameTime,
      isActive: this.gameState.isActive,
      winner: this.gameState.winner,
      yourTeam: player.team,
      yourElixir: player.elixir
    };
  }

  /**
   * Get the current game state
   */
  getState(): GameState {
    return this.gameState;
  }

  /**
   * Check if the game is active
   */
  isActive(): boolean {
    return this.gameState.isActive;
  }

  /**
   * Get the winner
   */
  getWinner(): TeamSide | null {
    return this.gameState.winner;
  }
}