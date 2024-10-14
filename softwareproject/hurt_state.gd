extends State

func enter_state(_prev_state: State):
	print("Entering HurtState")  # Debug statement to check if the state is entered

	# Properly access the AnimationPlayer node to play the animation
	var animator = actor.get_node_or_null("AnimationPlayer")

	if animator == null:
		print("Error: AnimationPlayer node not found!")
		return  # Exit the function if we can't find the AnimationPlayer

	# Create the Callable object for the animation_finished method
	var animation_callable = Callable(self, "animation_finished")

	# Connect the animation finished signal to this state's function (if not already connected)
	if not animator.is_connected("animation_finished", animation_callable):
		animator.connect("animation_finished", animation_callable)
		print("Connected animation_finished signal")

	print("Actor took damage, playing hurt animation")  # Debug statement to confirm damage

	actor.take_damage(10)  # Apply damage to the actor

	# Play the hurt animation based on the direction the Wraith was facing
	match actor.last_direction:
		Vector2.UP:
			animator.play("hurt_up")
		Vector2.DOWN:
			animator.play("hurt_down")
		Vector2.LEFT:
			animator.play("hurt_left")
		Vector2.RIGHT:
			animator.play("hurt_right")
		_:
			animator.play("hurt_down")  # Default to "hurt_down" if direction is unknown

	print("Hurt animation should now be playing")  # Debug statement to confirm the animation call
	actor.velocity = Vector2.ZERO
	previous_state = _prev_state

func exit_state():
	# Properly access the Sprite2D node to reset its color
	var sprite = actor.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color.WHITE
	else:
		print("Error: Sprite2D node not found!")

func animation_finished():
	# Emit a signal indicating that the hurt animation has finished
	emit_signal("hurt_animation_finished")

	# Start the invulnerability timer and only then transition to the next state
	var invul_timer = actor.get_node_or_null("Invultimer")
	if invul_timer:
		invul_timer.start()
		print("InvulTimer started")
	else:
		print("Error: Invultimer node not found!")

	# Perform the state transition logic after the hurt animation finishes
	actor.turn_to_player()
	transition.emit("RunState")
