extends State

var speed: float = 100.0
var direction: Vector2 = Vector2.ZERO

func enter_state(_previous_state: State):
	print("Entering RunState")

	# Pick a random direction at the start
	direction = get_random_direction()
	actor.current_direction = direction
	print("Moving in direction: ", direction)

	move_and_play_animation()

func physics_update(delta: float):
	# Handle movement and check for collisions
	move_and_check_for_collisions()

	# Transition to FollowState when player is detected
	if actor.player_in_range:
		if actor.global_position.distance_to(actor.player.global_position) <= actor.min_distance_to_player:
			transition.emit("AttackState")  # Transition to AttackState if close enough to attack
		else:
			transition.emit("FollowState")

# Function to move the wraith and check for collisions
func move_and_check_for_collisions():
	if actor.current_direction != Vector2.ZERO:
		actor.velocity = actor.current_direction * actor.speed
		actor.move_and_slide()

		# Check for collision
		if actor.get_last_slide_collision() != null:
			print("Collision detected, changing direction")
			change_direction()

		# Play the correct animation based on direction
		move_and_play_animation()
	else:
		print("Actor is not moving in RunState")

# Function to change the direction after collision
func change_direction():
	var new_direction = get_random_direction()

	# Ensure the new direction is different from the current one
	while new_direction == actor.current_direction:
		new_direction = get_random_direction()

	actor.current_direction = new_direction
	print("Changed direction to: ", actor.current_direction)

# Function to randomly choose a direction for the Wraith to move
func get_random_direction() -> Vector2:
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	return directions[randi() % directions.size()]

# Play the correct animation based on the current direction
func move_and_play_animation():
	if actor.animator:
		match actor.current_direction:
			Vector2.UP:
				actor.animator.play("walk_up")
			Vector2.DOWN:
				actor.animator.play("walk_down")
			Vector2.LEFT:
				actor.animator.play("walk_left")
			Vector2.RIGHT:
				actor.animator.play("walk_right")
	else:
		print("Error: Animator is null in RunState")
