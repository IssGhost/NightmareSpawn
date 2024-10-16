extends CharacterBody2D

# Health properties
@export var max_health: int = 50
var current_health: int = max_health

# Movement speed of the wraith
@export var speed: float = 100.0

# Invulnerability duration (in seconds)
@export var invul_duration: float = 1.0
var is_invulnerable: bool = false
var player_in_attack_range: bool = false

# Variables to track the direction
var last_direction: Vector2 = Vector2.DOWN
var current_direction: Vector2 = Vector2.ZERO

# Minimum distance to consider the player too close
@export var min_distance_to_player: float = 100.0

# References to necessary nodes
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var invul_timer: Timer = $Invultimer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_box: Area2D = $AttackBox  # Reference to the AttackBox node

# Reference to the state machine
@onready var fsm = $FiniteStateMachine

# Player reference (detected through signals)
var player: Node2D = null
var player_in_range: bool = false
@export var attack_range: float = 100.0  # Set a default value for attack range

func _ready():
	if attack_box:
		attack_box.connect("body_entered", Callable(self, "_on_attack_box_entered"))
		attack_box.connect("body_exited", Callable(self, "_on_attack_box_exited"))
	else:
		print("Error: AttackBox not found!")
	if fsm:
		fsm.actor = self  # Set the Wraith as the actor for the FSM
		fsm.animator = animator
		fsm.pivot = $Pivot  # Ensure you have a pivot node if required
	
	# Other initialization logic
	current_health = max_health

	# Connect the invulnerability timer signal if the timer exists
	if invul_timer:
		invul_timer.wait_time = invul_duration
		invul_timer.one_shot = true
		invul_timer.connect("timeout", Callable(self, "_on_invul_timer_timeout"))
	else:
		print("Error: Invultimer node not found!")

	# Connect signals for detection area if it exists
	if detection_area:
		detection_area.connect("body_entered", Callable(self, "_on_detection_area_entered"))
		detection_area.connect("body_exited", Callable(self, "_on_detection_area_exited"))
	else:
		print("Error: DetectionArea node not found!")

func _physics_process(delta: float):
	# Let the FSM handle movement and state-based behaviors
	if fsm:
		fsm._physics_process(delta)

# Movement logic, triggered by the FSM
func move_and_update_direction(delta: float):
	if current_direction != Vector2.ZERO:
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

func take_damage(amount: int):
	if is_invulnerable:
		print("Wraith is invulnerable and cannot take damage!")
		return

	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	print("Wraith took damage: ", amount, " - Current Health: ", current_health)

	# Trigger invulnerability timer
	is_invulnerable = true
	if invul_timer:
		invul_timer.start()

	# If health is 0 or below, transition to DieState
	if current_health <= 0:
		print("Health depleted, transitioning to DieState")
		if fsm and fsm.has_method("transition"):
			fsm.transition("DieState")  # Transition to the DieState
	else:
		# Otherwise, transition to HurtState
		if fsm and fsm.has_method("transition"):
			fsm.transition("HurtState")

# Function to check if the player is in range
func is_player_in_range() -> bool:
	return player_in_range

# Player detection logic (when they enter the detection area)
func _on_detection_area_entered(body: Node):
	if body.is_in_group("player"):  # Ensure the body is the player
		player_in_range = true
		player = body  # Set the player reference
		print("Player entered detection area")
	else:
		print("Non-player body entered detection area")

# Player exit logic (when they leave the detection area)
func _on_detection_area_exited(body: Node):
	if body.is_in_group("player"):
		player_in_range = false
		print("Player exited detection area")

func _on_attack_box_entered(body: Node):
	if body.is_in_group("player"):  # Ensure it's the player entering the attack box
		player_in_attack_range = true
		print("Player entered attack range")

func _on_attack_box_exited(body: Node):
	if body.is_in_group("player"):  # Ensure it's the player leaving the attack box
		player_in_attack_range = false
		print("Player left attack range")
# Function to turn the Wraith to face the player
func turn_to_player():
	if player:
		var direction_to_player = (player.global_position - global_position).normalized()
		if abs(direction_to_player.x) > abs(direction_to_player.y):
			last_direction = Vector2.RIGHT if direction_to_player.x > 0 else Vector2.LEFT
		else:
			last_direction = Vector2.DOWN if direction_to_player.y > 0 else Vector2.UP
		print("Wraith is now facing the player")

# Invulnerability timer timeout handler
func _on_invul_timer_timeout():
	is_invulnerable = false
	print("Wraith is no longer invulnerable")
