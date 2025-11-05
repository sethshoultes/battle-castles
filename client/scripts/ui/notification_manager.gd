extends CanvasLayer
class_name NotificationManager

# Global notification manager for level-up and other notifications
# Add as autoload to make notifications available from anywhere

var level_up_notification: LevelUpNotification = null

func _ready() -> void:
	# Load and instance the level-up notification scene
	var notification_scene = preload("res://scenes/ui/level_up_notification.tscn")
	level_up_notification = notification_scene.instantiate()
	add_child(level_up_notification)

	# Set to be on top of everything
	layer = 100

	print("NotificationManager ready")

func show_level_up(new_level: int, rewards: Dictionary) -> void:
	if level_up_notification:
		level_up_notification.show_notification(new_level, rewards)
