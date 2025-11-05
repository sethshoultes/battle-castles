extends Control
class_name LevelUpNotification

# Level up notification with celebration effects
# Shows when player levels up with rewards and animations

# UI Elements
@onready var background_overlay: ColorRect = $BackgroundOverlay
@onready var notification_panel: Panel = $NotificationPanel
@onready var level_up_label: Label = $NotificationPanel/VBoxContainer/LevelUpLabel
@onready var new_level_container: HBoxContainer = $NotificationPanel/VBoxContainer/NewLevelContainer
@onready var level_badge: Panel = $NotificationPanel/VBoxContainer/NewLevelContainer/LevelBadge
@onready var level_number: Label = $NotificationPanel/VBoxContainer/NewLevelContainer/LevelBadge/LevelNumber
@onready var rewards_container: VBoxContainer = $NotificationPanel/VBoxContainer/RewardsContainer
@onready var rewards_title: Label = $NotificationPanel/VBoxContainer/RewardsContainer/RewardsTitle
@onready var gold_reward_container: HBoxContainer = $NotificationPanel/VBoxContainer/RewardsContainer/GoldReward
@onready var gold_icon: Label = $NotificationPanel/VBoxContainer/RewardsContainer/GoldReward/GoldIcon
@onready var gold_amount: Label = $NotificationPanel/VBoxContainer/RewardsContainer/GoldReward/GoldAmount
@onready var gems_reward_container: HBoxContainer = $NotificationPanel/VBoxContainer/RewardsContainer/GemsReward
@onready var gems_icon: Label = $NotificationPanel/VBoxContainer/RewardsContainer/GemsReward/GemsIcon
@onready var gems_amount: Label = $NotificationPanel/VBoxContainer/RewardsContainer/GemsReward/GemsAmount
@onready var chest_reward_container: HBoxContainer = $NotificationPanel/VBoxContainer/RewardsContainer/ChestReward
@onready var chest_icon: Label = $NotificationPanel/VBoxContainer/RewardsContainer/ChestReward/ChestIcon
@onready var chest_label: Label = $NotificationPanel/VBoxContainer/RewardsContainer/ChestReward/ChestLabel
@onready var continue_button: Button = $NotificationPanel/VBoxContainer/ContinueButton

# Animation and effects
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var confetti_particles: GPUParticles2D = $ConfettiParticles
@onready var sparkle_particles: GPUParticles2D = $NotificationPanel/SparkleParticles
@onready var glow_particles: GPUParticles2D = $NotificationPanel/GlowParticles

# Audio
@onready var level_up_sound: AudioStreamPlayer = $LevelUpSound
@onready var reward_sound: AudioStreamPlayer = $RewardSound

# State
var current_level: int = 0
var current_rewards: Dictionary = {}
var is_showing: bool = false

# Signals
signal notification_closed()

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	hide_notification()

func _setup_ui() -> void:
	# Initially hide the notification
	modulate.a = 0.0
	visible = false

	# Set initial styles
	level_up_label.add_theme_font_size_override("font_size", 48)
	level_number.add_theme_font_size_override("font_size", 64)
	rewards_title.add_theme_font_size_override("font_size", 24)

	# Set colors
	level_up_label.modulate = Color(1.0, 0.9, 0.2, 1.0) # Gold
	level_badge.modulate = Color(1.0, 0.8, 0.0, 1.0) # Gold badge

	# Hide rewards initially
	rewards_container.visible = false
	continue_button.disabled = true
	continue_button.modulate.a = 0.0

	# Setup particles
	if not confetti_particles:
		confetti_particles = ParticleEffects.create_victory_confetti()
		add_child(confetti_particles)
		confetti_particles.position = Vector2(get_viewport_rect().size.x / 2, 0)
		confetti_particles.emitting = false

	if not sparkle_particles:
		sparkle_particles = ParticleEffects.create_from_preset("sparkle", {
			"color": Color(1.0, 0.9, 0.3, 1.0),
			"amount": 50,
			"lifetime": 2.0,
			"one_shot": false
		})
		notification_panel.add_child(sparkle_particles)
		sparkle_particles.position = notification_panel.size / 2
		sparkle_particles.emitting = false

	if not glow_particles:
		glow_particles = ParticleEffects.create_from_preset("sparkle", {
			"color": Color(1.0, 1.0, 0.5, 0.8),
			"amount": 30,
			"lifetime": 1.5,
			"velocity_min": 20.0,
			"velocity_max": 60.0,
			"one_shot": false,
			"texture_type": "glow"
		})
		notification_panel.add_child(glow_particles)
		glow_particles.position = notification_panel.size / 2
		glow_particles.emitting = false

func _connect_signals() -> void:
	continue_button.pressed.connect(_on_continue_pressed)

	# Connect to GameManager's PlayerProfile level_up signal when it's ready
	call_deferred("_connect_to_player_profile")

func _connect_to_player_profile() -> void:
	if GameManager and GameManager.player_profile:
		GameManager.player_profile.level_up.connect(_on_level_up)
		print("LevelUpNotification connected to PlayerProfile")

func _on_level_up(new_level: int, rewards: Dictionary) -> void:
	show_notification(new_level, rewards)

func show_notification(new_level: int, rewards: Dictionary) -> void:
	if is_showing:
		return

	is_showing = true
	current_level = new_level
	current_rewards = rewards

	# Update UI with new level
	level_number.text = str(new_level)

	# Setup rewards display
	_setup_rewards_display(rewards)

	# Show and animate
	visible = true
	_play_celebration_animation()

func _setup_rewards_display(rewards: Dictionary) -> void:
	# Reset visibility
	gold_reward_container.visible = false
	gems_reward_container.visible = false
	chest_reward_container.visible = false

	# Show gold reward
	if rewards.has("gold") and rewards.gold > 0:
		gold_icon.text = "💰"
		gold_amount.text = "+" + str(rewards.gold) + " Gold"
		gold_reward_container.visible = true

	# Show gems reward
	if rewards.has("gems") and rewards.gems > 0:
		gems_icon.text = "💎"
		gems_amount.text = "+" + str(rewards.gems) + " Gems"
		gems_reward_container.visible = true

	# Show chest reward
	if rewards.has("chest_type"):
		var chest_name = rewards.chest_type.capitalize().replace("_", " ")
		chest_icon.text = _get_chest_icon(rewards.chest_type)
		chest_label.text = chest_name + " Chest"
		chest_reward_container.visible = true

func _get_chest_icon(chest_type: String) -> String:
	match chest_type:
		"golden":
			return "📦✨"
		"giant":
			return "📦📦"
		"magical":
			return "🎁✨"
		"super_magical":
			return "🎁💫"
		"legendary":
			return "👑🎁"
		_:
			return "📦"

func _play_celebration_animation() -> void:
	# Play sound
	if level_up_sound:
		level_up_sound.play()

	# Start confetti
	if confetti_particles:
		confetti_particles.emitting = true

	# Create animation sequence with tweens
	var tween = create_tween()
	tween.set_parallel(false)

	# Fade in background overlay
	tween.tween_property(background_overlay, "modulate:a", 0.7, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)

	# Animate panel entrance with bounce
	notification_panel.scale = Vector2(0.3, 0.3)
	notification_panel.modulate.a = 0.0
	tween.tween_property(notification_panel, "scale", Vector2(1.1, 1.1), 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(notification_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(notification_panel, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_ELASTIC)

	# Animate "LEVEL UP!" text with pulse
	tween.tween_callback(_start_level_up_text_animation)
	tween.tween_interval(0.5)

	# Start particle effects
	tween.tween_callback(_start_particles)
	tween.tween_interval(0.3)

	# Animate level badge with rotation and scale
	tween.tween_callback(_animate_level_badge)
	tween.tween_interval(0.8)

	# Show rewards with stagger
	tween.tween_callback(_animate_rewards)
	tween.tween_interval(1.0)

	# Show continue button
	tween.tween_callback(_show_continue_button)

func _start_level_up_text_animation() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(level_up_label, "scale", Vector2(1.1, 1.1), 0.5)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(level_up_label, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_SINE)

func _start_particles() -> void:
	if sparkle_particles:
		sparkle_particles.emitting = true
	if glow_particles:
		glow_particles.emitting = true

func _animate_level_badge() -> void:
	level_badge.scale = Vector2(0.5, 0.5)
	level_badge.rotation = -PI / 4

	var tween = create_tween()
	tween.tween_property(level_badge, "scale", Vector2(1.2, 1.2), 0.5)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(level_badge, "rotation", PI / 8, 0.5)\
		.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(level_badge, "scale", Vector2.ONE, 0.2)
	tween.parallel().tween_property(level_badge, "rotation", 0.0, 0.2)

	# Pulse effect for level number
	var number_tween = create_tween()
	number_tween.set_loops()
	number_tween.tween_property(level_number, "modulate", Color(1.0, 1.0, 0.5, 1.0), 0.4)
	number_tween.tween_property(level_number, "modulate", Color.WHITE, 0.4)

func _animate_rewards() -> void:
	rewards_container.visible = true
	rewards_container.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(rewards_container, "modulate:a", 1.0, 0.3)

	# Play reward sound
	if reward_sound:
		reward_sound.play()

	# Animate each reward item with stagger
	var delay = 0.0
	for child in rewards_container.get_children():
		if child is HBoxContainer and child.visible:
			child.modulate.a = 0.0
			child.scale = Vector2(0.8, 0.8)

			var item_tween = create_tween()
			item_tween.tween_interval(delay)
			item_tween.tween_property(child, "modulate:a", 1.0, 0.2)
			item_tween.parallel().tween_property(child, "scale", Vector2(1.1, 1.1), 0.2)\
				.set_trans(Tween.TRANS_BACK)
			item_tween.tween_property(child, "scale", Vector2.ONE, 0.1)

			delay += 0.2

func _show_continue_button() -> void:
	continue_button.disabled = false

	var tween = create_tween()
	tween.tween_property(continue_button, "modulate:a", 1.0, 0.3)

	# Pulse effect
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(continue_button, "scale", Vector2(1.05, 1.05), 0.5)
	pulse_tween.tween_property(continue_button, "scale", Vector2.ONE, 0.5)

func _on_continue_pressed() -> void:
	hide_notification()

func hide_notification() -> void:
	if not is_showing:
		return

	# Stop particles
	if confetti_particles:
		confetti_particles.emitting = false
	if sparkle_particles:
		sparkle_particles.emitting = false
	if glow_particles:
		glow_particles.emitting = false

	# Fade out animation
	var tween = create_tween()
	tween.tween_property(notification_panel, "scale", Vector2(0.8, 0.8), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(notification_panel, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(background_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		visible = false
		is_showing = false
		notification_closed.emit()
	)

func _input(event: InputEvent) -> void:
	# Allow closing with Escape or clicking outside
	if is_showing and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			hide_notification()
	elif is_showing and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var panel_rect = notification_panel.get_global_rect()
			if not panel_rect.has_point(event.position):
				hide_notification()
