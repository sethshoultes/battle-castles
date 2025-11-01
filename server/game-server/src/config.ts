import { GameConfig, UnitStats, UnitType } from './types';

export const GAME_CONFIG: GameConfig = {
  tickRate: 20, // 20Hz server tick rate
  maxGameTime: 300000, // 5 minutes in milliseconds
  initialElixir: 5,
  maxElixir: 10,
  elixirRegenRate: 1.0, // 1 elixir per second
  doubleElixirTime: 180000, // Double elixir starts at 3 minutes
  suddenDeathTime: 240000, // Sudden death at 4 minutes
  deploymentZoneDepth: 3, // Units can be deployed within 3 units of your side
  mapWidth: 18,
  mapHeight: 32
};

export const UNIT_STATS: Record<UnitType, Omit<UnitStats, 'type'>> = {
  [UnitType.KNIGHT]: {
    health: 1000,
    maxHealth: 1000,
    damage: 150,
    attackSpeed: 1.2,
    moveSpeed: 1.0,
    attackRange: 1.5,
    elixirCost: 3,
    deployTime: 1000
  },
  [UnitType.ARCHER]: {
    health: 400,
    maxHealth: 400,
    damage: 100,
    attackSpeed: 1.0,
    moveSpeed: 1.2,
    attackRange: 5.0,
    elixirCost: 2,
    deployTime: 1000
  },
  [UnitType.WIZARD]: {
    health: 600,
    maxHealth: 600,
    damage: 200,
    attackSpeed: 1.5,
    moveSpeed: 0.8,
    attackRange: 4.5,
    elixirCost: 4,
    deployTime: 1000
  },
  [UnitType.GIANT]: {
    health: 3000,
    maxHealth: 3000,
    damage: 250,
    attackSpeed: 2.0,
    moveSpeed: 0.6,
    attackRange: 1.5,
    elixirCost: 5,
    deployTime: 1500
  },
  [UnitType.GOBLIN]: {
    health: 200,
    maxHealth: 200,
    damage: 80,
    attackSpeed: 0.8,
    moveSpeed: 2.0,
    attackRange: 1.0,
    elixirCost: 1,
    deployTime: 500
  },
  [UnitType.DRAGON]: {
    health: 2000,
    maxHealth: 2000,
    damage: 300,
    attackSpeed: 1.8,
    moveSpeed: 1.5,
    attackRange: 3.5,
    elixirCost: 7,
    deployTime: 2000
  }
};

export const TOWER_CONFIG = {
  MAIN_TOWER: {
    health: 4000,
    maxHealth: 4000,
    damage: 150,
    attackSpeed: 1.0,
    attackRange: 7.0
  },
  SIDE_TOWER: {
    health: 2500,
    maxHealth: 2500,
    damage: 100,
    attackSpeed: 0.8,
    attackRange: 6.0
  }
};

export const SERVER_CONFIG = {
  PORT: parseInt(process.env.PORT || '3001'),
  CORS_ORIGIN: process.env.CORS_ORIGIN || '*',
  LOG_LEVEL: process.env.LOG_LEVEL || 'info',
  MAX_ROOMS: parseInt(process.env.MAX_ROOMS || '100'),
  ROOM_CLEANUP_INTERVAL: 30000, // Clean up empty rooms every 30 seconds
  PLAYER_TIMEOUT: 10000, // Disconnect player after 10 seconds of no response
  MATCHMAKING_TIMEOUT: 30000 // Cancel matchmaking after 30 seconds
};