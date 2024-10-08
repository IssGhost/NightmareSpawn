extends CharacterBody2D

# Movement speed of the wraith
var speed: float = 100.0

# Reference to the AnimationPlayer node
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Direction vector for movement
var direction: Vector2 = Vector2.ZERO

func _ready():
	set_random_direction()

func _process(delta: float):
	move_and_play_animation(delta)

func set_random_direction():
	# Randomly choose a direction for the Wraith to move in
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	direction = directions[randi() % directions.size()]

func move_and_play_animation(delta: float):
	if direction != Vector2.ZERO:
		# Move the Wraith using move_and_slide to handle collisions properly
		velocity = direction * speed
		var collision_info = move_and_slide()

		# Check if a collision occurred
		if collision_info:
			print("Collision detected, changing direction")
			set_random_direction()  # Change direction on collision

		# Play the appropriate animation based on the direction
		match direction:
			Vector2.UP:
				animation_player.play("walk_up")
			Vector2.DOWN:
				animation_player.play("walk_down")
			Vector2.LEFT:
				animation_player.play("walk_left")
			Vector2.RIGHT:
				animation_player.play("walk_right")

func is_at_room_edge() -> bool:
	# Add logic here to check if the Wraith is near the edge of the room
	# This is a placeholder function, you can adjust it based on your room's dimensions
	return false  # Replace this with the actual check for room boundaries
