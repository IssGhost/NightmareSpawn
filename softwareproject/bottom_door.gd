extends Node2D  # Or whatever your parent node is

# This function is called when something enters the Area2D (collision detection)
func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):  # Check if the entering body is the player
		print("Player collided with door!")
		# Get the AnimatedSprite2D node
		var animated_sprite = $BottomDoorAnimation
		# Play the appropriate animation
		animated_sprite.play("Bottom")  # Replace with the actual animation name
