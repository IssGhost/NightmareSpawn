extends Node2D

# Variables for chest room
var chests = []
var rewards = ["Gold", "Potion", "Magic Scroll"]

func _ready():
	# Initialize the chest room
	spawn_chests()

func spawn_chests():
	print("Chests have spawned!")
	# Add logic to create and place chests
	for i in range(2):  # Assuming 2 chests for this room
		var chest = {"is_open": false, "reward": rewards[i]}
		chests.append(chest)

func open_chest(chest_index):
	if not chests[chest_index]["is_open"]:
		chests[chest_index]["is_open"] = true
		print("Chest opened! Reward: %s" % chests[chest_index]["reward"])
	else:
		print("Chest is already open!")
