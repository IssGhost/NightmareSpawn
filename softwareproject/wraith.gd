extends CharacterBody2D

# Health properties
@export var max_health: int = 50
var current_health: int = max_health

# Movement speed of the wraith
@export var speed: float = 100.0

# Invulnerability duration (in seconds)
@export var invul_duration: float = 1.0
var is_invulnerable: bool = false  # Tracks if the Wraith is currently invulnerable

# Variables to track the direction
var last_direction: Vector2 = Vector2.DOWN  # Default to facing down
var current_direction: Vector2 = Vector2.ZERO

# Minimum distance to consider the player too close
@export var min_distance_to_player: float = 100.0  # Adjust this value based on your needs

# Reference to the AnimationPlayer and Timer nodes
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var invul_timer: Timer = $Invultimer  # Updated to match the exact node name and path

# Reference to the state machine (assuming it's a parent node)
@onready var fsm = $FiniteStateMachine

func _ready():
	# Initialize the Wraith character
	last_direction = Vector2.DOWN  # Set a default direction if needed
	current_health = max_health

	# Set up the invulnerability timer
	if invul_timer:
		invul_timer.wait_time = invul_duration
		invul_timer.one_shot = true  # Make sure the timer stops automatically after reaching the wait time
		invul_timer.connect("timeout", Callable(self, "_on_invul_timer_timeout"))
	else:
		print("Error: Invultimer node not found!")

func _physics_process(delta: float):
	# Only perform movement if the Wraith is not in HurtState
	if fsm.current_state and fsm.current_state.name != "HurtState":
		move_and_update_direction(delta)

func move_and_update_direction(delta: float):
	# Assuming your Wraith has simple logic to move in a direction
	if current_direction != Vector2.ZERO:
		# Update the last known direction before moving
		if abs(current_direction.x) > abs(current_direction.y):
			last_direction = Vector2.RIGHT if current_direction.x > 0 else Vector2.LEFT
		else:
			last_direction = Vector2.DOWN if current_direction.y > 0 else Vector2.UP

		velocity = current_direction * speed
		move_and_slide()

		# Play the appropriate walk animation based on the direction
		match last_direction:
			Vector2.UP:
				animator.play("walk_up")
			Vector2.DOWN:
				animator.play("walk_down")
			Vector2.LEFT:
				animator.play("walk_left")
			Vector2.RIGHT:
				animator.play("walk_right")


# New function to handle taking damage with invulnerability logic
func take_damage(amount: int):
	# Check if the Wraith is currently invulnerable
	if is_invulnerable:
		print("Wraith is invulnerable and cannot take damage!")
		return

	# Reduce the Wraith's health by the damage amount
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)  # Ensure health doesn't go below 0 or above max

	print("Wraith took damage: ", amount, " - Current Health: ", current_health)

	# Start the invulnerability timer
	is_invulnerable = true
	if invul_timer:
		invul_timer.start()
	else:
		print("Error: Invultimer node not found!")

	# Check if the Wraith's health is depleted and handle death logic
	if current_health <= 0:
		die()
	else:
		# Transition to HurtState when the Wraith takes damage but is not dead
		if fsm and fsm.has_method("transition"):
			fsm.transition("HurtState")

# Function to check if the player is too close to the Wraith
func is_too_close() -> bool:
	var player = get_tree().get_nodes_in_group("Player")
	if player.size() > 0:
		var distance_to_player = global_position.distance_to(player[0].global_position)
		return distance_to_player < min_distance_to_player
	return false

# Function to turn the Wraith to face the player
func turn_to_player():
	var player = get_tree().get_nodes_in_group("Player")
	if player.size() > 0:
		var direction_to_player = (player[0].global_position - global_position).normalized()
		if abs(direction_to_player.x) > abs(direction_to_player.y):
			last_direction = Vector2.RIGHT if direction_to_player.x > 0 else Vector2.LEFT
		else:
			last_direction = Vector2.DOWN if direction_to_player.y > 0 else Vector2.UP
		print("Wraith is now facing the player")

# Function to handle the end of the invulnerability period
func _on_invul_timer_timeout():
	is_invulnerable = false
	print("Wraith is no longer invulnerable")

func die():
	print("Wraith has been defeated!")
	
	# Play the death animation based on the last direction
	if last_direction == Vector2.RIGHT or Vector2.UP:
		animator.play("die_right")
	elif last_direction == Vector2.LEFT or Vector2.DOWN:
		animator.play("die_left")
	else:
		animator.play("die_down")  # Default to down if the direction is vertical

	# Disable further input or interactions
	set_physics_process(false)
	set_process(false)

	# Ensure that the Wraith won't move or be affected by collisions during the death animation
	velocity = Vector2.ZERO

	# Connect to the 'animation_finished' signal, or make sure it's connected in _ready
	if not animator.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
		animator.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

func _on_death_animation_finished(anim_name: String):
	# Ensure that the animation played is the death animation before freeing the Wraith
	if anim_name == "die_right" or anim_name == "die_left" or anim_name == "die_down":
		queue_free()  # Remove the Wraith from the scene
