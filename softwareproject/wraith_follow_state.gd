extends State

class_name FollowState

var speed: float = 75.0  # Speed when following the player

func enter_state(_previous_state: State):
	print("Entering FollowState")
	if actor.player:
		print("Player detected, following...")

	# Set the appropriate walking animation based on player's direction
	move_towards_player(0)

func exit_state():
	# Stop the actor when exiting FollowState
	actor.velocity = Vector2.ZERO

func physics_update(delta: float):
	# Follow the player if they exist
	move_towards_player(delta)
	# If player leaves detection area, transition back to RunState
	if not actor.player_in_range:
		print("Player out of range, switching back to RunState")
		transition.emit("RunState")
	if actor.player:
		# Check if the player is within attack range
		if actor.global_position.distance_to(actor.player.global_position) <= actor.min_distance_to_player:
			transition.emit("AttackState")  # Transition to AttackState if close enough to attack
		else:
			move_towards_player(delta)
# Move towards the player's position
func move_towards_player(delta: float):
	if actor.player:
		# Calculate the direction to the player
		var direction = (actor.player.global_position - actor.global_position).normalized()
		
		# Set the actor's velocity in the direction of the player
		actor.velocity = direction * speed
		
		# Move the actor
		actor.move_and_slide()  # No argument needed

		# Play animation based on the direction of movement
		move_and_play_animation(direction)

		# If player leaves detection area, transition back to RunState
		if not actor.player_in_range:
			transition.emit("RunState")

# Update the animation based on the movement direction
func move_and_play_animation(direction: Vector2):
	if direction != Vector2.ZERO:
		# Play animation based on direction
		if direction.y < 0:
			actor.animator.play("walk_up")
		elif direction.y > 0:
			actor.animator.play("walk_down")
		elif direction.x < 0:
			actor.animator.play("walk_left")
		elif direction.x > 0:
			actor.animator.play("walk_right")
