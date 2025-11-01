/**
 * Type definitions for Battle Castles game server
 */

export interface Vector2 {
  x: number;
  y: number;
}

export enum TeamSide {
  LEFT = 'left',
  RIGHT = 'right'
}

export enum UnitType {
  KNIGHT = 'knight',
  ARCHER = 'archer',
  WIZARD = 'wizard',
  GIANT = 'giant',
  GOBLIN = 'goblin',
  DRAGON = 'dragon'
}

export enum TowerType {
  MAIN = 'main',
  LEFT = 'left',
  RIGHT = 'right'
}

export interface UnitStats {
  type: UnitType;
  health: number;
  maxHealth: number;
  damage: number;
  attackSpeed: number;
  moveSpeed: number;
  attackRange: number;
  elixirCost: number;
  deployTime: number;
}

export interface Unit {
  id: string;
  type: UnitType;
  team: TeamSide;
  position: Vector2;
  health: number;
  maxHealth: number;
  target: string | null;
  lastAttackTime: number;
  stats: UnitStats;
  isAlive: boolean;
  deployedAt: number;
}

export interface Tower {
  id: string;
  type: TowerType;
  team: TeamSide;
  position: Vector2;
  health: number;
  maxHealth: number;
  damage: number;
  attackSpeed: number;
  attackRange: number;
  lastAttackTime: number;
  isDestroyed: boolean;
}

export interface Player {
  id: string;
  socketId: string;
  name: string;
  team: TeamSide;
  elixir: number;
  maxElixir: number;
  elixirRegenRate: number;
  lastElixirUpdate: number;
  isConnected: boolean;
  crowns: number;
}

export enum CommandType {
  DEPLOY_UNIT = 'deploy_unit',
  CAST_SPELL = 'cast_spell',
  SURRENDER = 'surrender'
}

export interface DeployUnitCommand {
  type: CommandType.DEPLOY_UNIT;
  unitType: UnitType;
  position: Vector2;
  timestamp: number;
}

export interface CastSpellCommand {
  type: CommandType.CAST_SPELL;
  spellType: string;
  position: Vector2;
  timestamp: number;
}

export interface SurrenderCommand {
  type: CommandType.SURRENDER;
  timestamp: number;
}

export type GameCommand = DeployUnitCommand | CastSpellCommand | SurrenderCommand;

export interface GameState {
  roomId: string;
  players: Map<string, Player>;
  units: Map<string, Unit>;
  towers: Map<string, Tower>;
  gameTime: number;
  startTime: number;
  isActive: boolean;
  winner: TeamSide | null;
  lastUpdateTime: number;
}

export interface GameConfig {
  tickRate: number;
  maxGameTime: number;
  initialElixir: number;
  maxElixir: number;
  elixirRegenRate: number;
  doubleElixirTime: number;
  suddenDeathTime: number;
  deploymentZoneDepth: number;
  mapWidth: number;
  mapHeight: number;
}

export interface RoomState {
  id: string;
  players: Player[];
  gameState: GameState;
  isWaitingForPlayer: boolean;
  createdAt: number;
}

export interface ClientGameState {
  roomId: string;
  players: Player[];
  units: Unit[];
  towers: Tower[];
  gameTime: number;
  isActive: boolean;
  winner: TeamSide | null;
  yourTeam: TeamSide;
  yourElixir: number;
}

export interface ValidationResult {
  valid: boolean;
  error?: string;
}

export interface SocketMessage<T = any> {
  type: string;
  payload: T;
  timestamp: number;
}

export enum SocketEvent {
  // Client -> Server
  JOIN_QUEUE = 'join_queue',
  LEAVE_QUEUE = 'leave_queue',
  GAME_COMMAND = 'game_command',
  PING = 'ping',

  // Server -> Client
  QUEUE_JOINED = 'queue_joined',
  QUEUE_LEFT = 'queue_left',
  GAME_FOUND = 'game_found',
  GAME_STATE_UPDATE = 'game_state_update',
  GAME_ENDED = 'game_ended',
  ERROR = 'error',
  PONG = 'pong'
}

export interface GameEndedPayload {
  winner: TeamSide;
  reason: 'towers_destroyed' | 'time_limit' | 'surrender' | 'disconnect';
  finalState: ClientGameState;
}