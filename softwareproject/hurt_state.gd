extends State

func enter_state(_prev_state: State):
	print("Entering HurtState")

	if actor == null:
		print("Error: Actor is null!")
		return

	# Access the AnimationPlayer node from the actor
	var animator = actor.get_node_or_null("AnimationPlayer")
	if animator == null:
		print("Error: AnimationPlayer node not found!")
		return

	# Create the Callable object for the animation_finished method
	var animation_callable = Callable(self, "animation_finished")

	# Connect the animation finished signal to this state's function (if not already connected)
	if not animator.is_connected("animation_finished", animation_callable):
		animator.connect("animation_finished", animation_callable)

	print("Actor took damage, playing hurt animation")
	actor.take_damage(10)  # Apply damage to the actor

	# Transition to DieState if health is zero or below
	if actor.current_health <= 0:
		print("Wraith has no health left, transitioning to DieState")
		transition.emit("DieState")
		return

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
			animator.play("hurt_down")

	print("Hurt animation should now be playing")
	actor.velocity = Vector2.ZERO

	# Add a small timer to transition back to RunState after HurtState is over
	var hurt_timer = Timer.new()
	hurt_timer.wait_time = 0.5
	hurt_timer.one_shot = true
	actor.add_child(hurt_timer)
	hurt_timer.connect("timeout", Callable(self, "_on_hurt_timer_timeout"))
	hurt_timer.start()

func _on_hurt_timer_timeout():
	if actor.current_health > 0:
		transition.emit("RunState")
