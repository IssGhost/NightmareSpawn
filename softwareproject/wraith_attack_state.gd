extends State

class_name AttackState

var attack_range: float = 50.0  # Wraith attack range
var attack_duration: float = 0.5  # Duration of the attack
var attack_damage: int = 10  # Damage dealt by the Wraith
var cooldown_duration: float = 1.5  # Attack cooldown duration

var can_attack: bool = true

# Called when entering the state
func enter_state(_previous_state: State):
	print("Entering AttackState")
	
	# Only attack if cooldown allows it
	if can_attack and actor.player:
		attack()

func attack():
	# Determine direction based on the relative position of Wraith and player
	var direction_to_player = (actor.player.global_position - actor.global_position).normalized()

	# Prioritize horizontal direction (left or right)
	if abs(direction_to_player.x) > abs(direction_to_player.y):
		if direction_to_player.x < 0:
			actor.animator.play("attack_left")
		elif direction_to_player.x > 0:
			actor.animator.play("attack_right")
	else:
		# Otherwise, use vertical direction (up or down)
		if direction_to_player.y < 0:
			actor.animator.play("attack_up")
		elif direction_to_player.y > 0:
			actor.animator.play("attack_down")

	# Deal damage if the player is within range
	if actor.global_position.distance_to(actor.player.global_position) <= attack_range:
		deal_damage()

	# Start the attack timer (for attack duration)
	var attack_timer = Timer.new()
	attack_timer.wait_time = attack_duration
	attack_timer.one_shot = true
	add_child(attack_timer)
	attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	attack_timer.start()

	# Disable further attacks until the cooldown is over
	can_attack = false
	
	# Start the cooldown timer
	var cooldown_timer = Timer.new()
	cooldown_timer.wait_time = cooldown_duration
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)
	cooldown_timer.connect("timeout", Callable(self, "_on_cooldown_timeout"))
	cooldown_timer.start()

# Handles dealing damage to the player
func deal_damage():
	if actor.player and actor.player.is_in_group("Player"):
		actor.player.call("take_damage", attack_damage)
		print("Dealt damage to the player")

# Called when the attack animation is finished
func _on_attack_timer_timeout():
	print("Attack finished, transitioning to FollowState")
	transition.emit("FollowState")  # Move back to follow state or idle state after attacking

# Called when the cooldown timer finishes
func _on_cooldown_timeout():
	print("Cooldown finished, can attack again")
	can_attack = true
	
	# After the cooldown, check if the player is still in range
	if actor.global_position.distance_to(actor.player.global_position) <= attack_range:
		# If the player is still in range, transition back to attack
		transition.emit("AttackState")
	else:
		# Otherwise, keep following the player
		transition.emit("FollowState")

func exit_state():
	print("Exiting AttackState")
