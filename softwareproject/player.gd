extends CharacterBody2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D  # Assuming you have a Sprite node named Sprite
@onready var attack_box: Area2D = $AttackBox  # Assuming you have an Area2D node named AttackBox
@onready var hurt_box: Area2D = $Hurtbox  # Assuming you have an Area2D node named HurtBox
@onready var sound_effect = $AudioStreamPlayer2D
@export var speed = 1000
var current_dir = "none"
var is_attacking = false
var attack_damage = 10  # Damage dealt by the player when attacking

func _ready():
	anim.play("front_idle")
	attack_box.connect("body_entered", Callable(self, "_on_attack_box_body_entered"))
	anim.connect("animation_finished", Callable(self, "_on_animation_finished"))
	add_to_group("player")

func _physics_process(delta):
	if not is_attacking:  # Only allow movement if the player is not attacking
		player_movement(delta)

func player_movement(delta):
	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		play_anim(1)
		velocity.x = speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		play_anim(1)
		velocity.x = -speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		play_anim(1)
		velocity.y = speed
		velocity.x = 0
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		play_anim(1)
		velocity.y = -speed
		velocity.x = 0
	else:
		play_anim(0)
		velocity = Vector2.ZERO

	move_and_slide()

func play_anim(movement):
	if is_attacking:  # Prevent other animations from playing while attacking
		return

	var dir = current_dir

	if dir == "right":
		sprite.flip_h = false  # Flipping the sprite to face the right direction
		if movement == 1:
			anim.play("right_walk")
		else:
			anim.play("right_idle")

	elif dir == "left":
		if movement == 1:
			anim.play("left_walk")
		else:
			anim.play("left_idle")

	elif dir == "down":
		sprite.flip_h = false  # Reset flip for down direction
		if movement == 1:
			anim.play("front_walk")
		else:
			anim.play("front_idle")

	elif dir == "up":
		sprite.flip_h = false  # Reset flip for up direction
		if movement == 1:
			anim.play("back_walk")
		else:
			anim.play("back_idle")

func _input(event):
	if event.is_action_pressed("attack"):  # This checks for the attack key press
		attack()
var sound_is_playing = false
# Function to handle player attacks
func attack():
	if is_attacking:
		return  # If already attacking, don't start another attack
	if sound_is_playing == false:
		var random_pitch = randf_range(0.8, 1.6)  # Adjust pitch scale randomly
		$AudioStreamPlayer2D.pitch_scale = random_pitch
		$AudioStreamPlayer2D.play()
		sound_effect.play()
		sound_is_playing = true
	is_attacking = true  # Lock movement while attacking
	print("Attack started")

	# Activate the attack box when starting an attack
	attack_box.attacker = self
	attack_box.activate()

	# Play the attack animation based on the current direction
	match current_dir:
		"right":
			anim.play("right_attack")
			
		"left":
			anim.play("left_attack")
		"down":
			anim.play("front_attack")
		"up":
			anim.play("back_attack")

# Function to handle when an animation finishes playing
func _on_animation_finished(animation_name: String):
	if animation_name.ends_with("attack"):
		print("Attack finished")
		is_attacking = false  # Unlock movement after the attack animation is finished
		sound_is_playing = false
		# Deactivate the attack box when the attack animation is finished
		attack_box.deactivate()


# Function to handle damage to other entities when they enter the attack box
func _on_attack_box_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)

# Function to handle taking damage from other entities when the player is hit
func take_damage(amount: int):
	# Implement logic to reduce player's health
	print("Player took damage: ", amount)
	# You can include additional logic like playing a hurt animation or triggering invincibility
