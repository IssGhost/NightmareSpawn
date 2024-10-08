extends Node2D  # Or another appropriate base class

# Variables specific to the BossRoom
var boss_health = 100
var is_boss_defeated = false

func _ready():
	# Initialize boss room elements
	spawn_boss()

func spawn_boss():
	print("Boss has spawned!")
	# Add logic to spawn the boss, set its position, etc.

func on_boss_defeated():
	is_boss_defeated = true
	print("Boss has been defeated!")
	# Add logic for when the boss is defeated
