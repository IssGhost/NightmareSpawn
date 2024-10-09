extends Node2D

# Reference to the AnimatedSprite2D node
@onready var spawn_animation: AnimatedSprite2D = $SpawnAnimation

# Variable to store the enemy scene to be spawned
var enemy_scene: PackedScene

# Function to initialize the spawn process
func start_spawn_process(new_enemy_scene: PackedScene):
	# Store the enemy scene
	enemy_scene = new_enemy_scene
	
	# Check if the spawn animation node is valid before calling play()
	if spawn_animation != null:
		# Play the spawn animation from the start
		spawn_animation.play("default")
	else:
		print("Error: Spawn animation node is null!")

# Callback when the spawn animation finishes
func _on_SpawnAnimation_animation_finished():
	# Check if the enemy scene is valid
	if enemy_scene != null:
		# Instance the enemy and place it above the spawn point
		var enemy_instance = enemy_scene.instantiate()
		enemy_instance.position = position  # Spawn at the same position as this node
		get_parent().add_child(enemy_instance)  # Add the enemy to the scene tree

		print("Enemy spawned at position: ", enemy_instance.position)
		
		# Clean up the spawn animation node after the enemy spawns
		queue_free()
	else:
		print("Error: Enemy scene is null!")
