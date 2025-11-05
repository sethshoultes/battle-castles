extends Control

# Simple test UI to trigger level-up notifications
# This can be added to the progression test scene or run standalone

@onready var level_up_button: Button = $VBoxContainer/LevelUpButton
@onready var add_xp_button: Button = $VBoxContainer/AddXPButton
@onready var current_level_label: Label = $VBoxContainer/CurrentLevelLabel
@onready var current_xp_label: Label = $VBoxContainer/CurrentXPLabel

func _ready() -> void:
	# Connect buttons
	level_up_button.pressed.connect(_on_level_up_pressed)
	add_xp_button.pressed.connect(_on_add_xp_pressed)

	# Update labels
	_update_labels()

	# Connect to profile updates
	if GameManager and GameManager.player_profile:
		GameManager.player_profile.profile_updated.connect(_update_labels)

func _update_labels() -> void:
	if GameManager and GameManager.player_profile:
		var profile = GameManager.player_profile
		current_level_label.text = "Current Level: %d" % profile.player_data.level
		current_xp_label.text = "XP: %d / %d" % [profile.player_data.experience, profile.player_data.experience_to_next]

func _on_level_up_pressed() -> void:
	# Trigger a level-up by adding enough XP
	if GameManager and GameManager.player_profile:
		var profile = GameManager.player_profile
		var xp_needed = profile.player_data.experience_to_next - profile.player_data.experience + 1
		profile.add_experience(xp_needed)

func _on_add_xp_pressed() -> void:
	# Add a small amount of XP
	if GameManager and GameManager.player_profile:
		GameManager.player_profile.add_experience(50)
