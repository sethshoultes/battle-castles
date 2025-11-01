extends Node
class_name BattleManager

# Battle timing constants
const BATTLE_DURATION := 180.0  # 3 minutes in seconds
const OVERTIME_DURATION := 60.0  # 1 minute overtime
const DOUBLE_ELIXIR_TIME := 60.0  # Last 60 seconds is double elixir

# Battle state
enum BattleState { STARTING, IN_PROGRESS, OVERTIME, ENDED }
var state: BattleState = BattleState.STARTING
var battle_time: float = 0.0
var is_overtime: bool = false
var is_double_elixir: bool = false

# Score tracking
var player_crowns: int = 0
var opponent_crowns: int = 0
var player_towers_destroyed: Array = [false, false]  # Left, Right
var opponent_towers_destroyed: Array = [false, false]  # Left, Right
var player_castle_destroyed: bool = false
var opponent_castle_destroyed: bool = false

# Team constants
const TEAM_PLAYER := 0
const TEAM_OPPONENT := 1

# Signals
signal battle_started()
signal battle_ended(winner: int)
signal crown_scored(team: int, crowns: int)
signal double_elixir_started()
signal overtime_started()
signal time_updated(time_remaining: float)

# References
var battlefield: Node2D
var elixir_manager: ElixirManager

func _ready() -> void:
	set_process(false)

func initialize(battlefield_ref: Node2D, elixir_ref: ElixirManager) -> void:
	battlefield = battlefield_ref
	elixir_manager = elixir_ref

func start_battle() -> void:
	state = BattleState.IN_PROGRESS
	battle_time = BATTLE_DURATION
	set_process(true)
	battle_started.emit()

func _process(delta: float) -> void:
	if state != BattleState.IN_PROGRESS and state != BattleState.OVERTIME:
		return

	# Update battle time
	battle_time -= delta
	time_updated.emit(battle_time)

	# Check for double elixir mode
	if not is_double_elixir and state == BattleState.IN_PROGRESS and battle_time <= DOUBLE_ELIXIR_TIME:
		activate_double_elixir()

	# Check for battle end or overtime
	if battle_time <= 0:
		if state == BattleState.IN_PROGRESS:
			check_for_overtime()
		elif state == BattleState.OVERTIME:
			end_battle()

	check_victory_conditions()

func activate_double_elixir() -> void:
	is_double_elixir = true
	if elixir_manager:
		elixir_manager.set_double_elixir(true)
	double_elixir_started.emit()

func check_for_overtime() -> void:
	# If tied, go to overtime
	if player_crowns == opponent_crowns:
		state = BattleState.OVERTIME
		is_overtime = true
		battle_time = OVERTIME_DURATION
		overtime_started.emit()
	else:
		end_battle()

func spawn_unit(unit_type: String, position: Vector2, team: int) -> Node2D:
	# This will be implemented to spawn units on the battlefield
	if not battlefield:
		push_error("Battlefield not initialized")
		return null

	# Unit spawning logic will go here
	# For now, return null as placeholder
	return null

func check_victory_conditions() -> void:
	if state == BattleState.ENDED:
		return

	# Instant win if castle destroyed
	if player_castle_destroyed:
		opponent_crowns = 3
		end_battle()
	elif opponent_castle_destroyed:
		player_crowns = 3
		end_battle()

func tower_destroyed(team: int, tower_type: String) -> void:
	match team:
		TEAM_PLAYER:
			if tower_type == "castle":
				player_castle_destroyed = true
				opponent_crowns = 3
			elif tower_type == "left":
				player_towers_destroyed[0] = true
				opponent_crowns += 1
			elif tower_type == "right":
				player_towers_destroyed[1] = true
				opponent_crowns += 1
			crown_scored.emit(TEAM_OPPONENT, opponent_crowns)

		TEAM_OPPONENT:
			if tower_type == "castle":
				opponent_castle_destroyed = true
				player_crowns = 3
			elif tower_type == "left":
				opponent_towers_destroyed[0] = true
				player_crowns += 1
			elif tower_type == "right":
				opponent_towers_destroyed[1] = true
				player_crowns += 1
			crown_scored.emit(TEAM_PLAYER, player_crowns)

	check_victory_conditions()

func end_battle() -> void:
	state = BattleState.ENDED
	set_process(false)

	var winner: int = -1  # -1 for draw
	if player_crowns > opponent_crowns:
		winner = TEAM_PLAYER
	elif opponent_crowns > player_crowns:
		winner = TEAM_OPPONENT

	battle_ended.emit(winner)

func get_time_remaining() -> float:
	return max(0.0, battle_time)

func get_time_string() -> String:
	var time := get_time_remaining()
	var minutes := int(time) / 60
	var seconds := int(time) % 60
	return "%d:%02d" % [minutes, seconds]