extends State

var speed: float = 100.0
var direction: Vector2 = Vector2.ZERO

func enter_state(_previous_state: State):
	print("Entering RunState")
	# Set an initial direction for the Wraith
	direction = get_random_direction()
	actor.current_direction = direction  # Set the Wraith's current direction
	print("RunState: Initial direction set to: ", direction)
	move_and_play_animation(actor)

func update_state(actor, delta):
	# Handle movement and animation updates each frame
	move_and_play_animation(actor)

func get_random_direction() -> Vector2:
	# Randomly choose a direction for the Wraith to move in
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	return directions[randi() % directions.size()]

func move_and_play_animation(actor):
	if actor.current_direction != Vector2.ZERO:
		# Set the character's velocity based on direction and speed
		actor.velocity = actor.current_direction * speed
		print("Moving with velocity: ", actor.velocity)

		# Move the character using move_and_slide (no arguments needed in Godot 4)
		actor.move_and_slide()

		# Check if a collision occurred and change direction immediately
		if actor.get_last_slide_collision() != null:
			print("Collision detected, changing direction")
			actor.current_direction = get_random_direction()
			actor.velocity = actor.current_direction * speed  # Update velocity for new direction
			actor.move_and_slide()  # Reapply movement after direction change

		# Update last_direction based on movement for animation purposes
		if abs(actor.current_direction.x) > abs(actor.current_direction.y):
			actor.last_direction = Vector2.RIGHT if actor.current_direction.x > 0 else Vector2.LEFT
		else:
			actor.last_direction = Vector2.DOWN if actor.current_direction.y > 0 else Vector2.UP

		# Play the appropriate walk animation based on the last known direction
		print("Playing walk animation for direction: ", actor.last_direction)
		match actor.last_direction:
			Vector2.UP:
				actor.animator.play("walk_up")
			Vector2.DOWN:
				actor.animator.play("walk_down")
			Vector2.LEFT:
				actor.animator.play("walk_left")
			Vector2.RIGHT:
				actor.animator.play("walk_right")
	else:
		print("Wraith is not moving in RunState")
