extends Node2D  # or the appropriate type for your parent node

@onready var animated_sprite = $Area2D/LeftDoorAnimation

# This function is automatically created by the signal connection process
func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		print("Player collided with Bottom Door")
		animated_sprite.play("Left")  # Play the "Bottom" animation
