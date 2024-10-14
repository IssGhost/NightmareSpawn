extends TileMap  # This needs to be attached to a TileMap node

# Constants
const MAP_WIDTH = 125
const MAP_HEIGHT = 100
const MIN_LEAF_SIZE = 24  # Smaller leaf size
const MAX_LEAF_SIZE = 32  # Smaller maximum leaf size
const MIN_ROOM_SIZE = 16 # Smaller room size
const MAX_ROOMS = 15  # Limit the number of rooms to 15
const CAMERA_SPEED = 2000  # Speed for camera movement
const ZOOM_SPEED = 0.5  # Speed for zooming the camera

# Variables for HUD labels
var boss_label
var shop_label
var chest_label

# Global variables
var leaves = []
var root_leaf
var room_count = 0  # Counter to track number of generated rooms
var current_seed = 0
# Room class
class Room:
	var id
	var rect
	var connections = []
	var enemies = []

	func _init(_id, _rect):
		id = _id
		rect = _rect

# Union-Find class for Kruskal's algorithm
class UnionFind:
	var parent = {}
	
	func make_set(x):
		parent[x] = x
	
	func find(x):
		if parent[x] != x:
			parent[x] = find(parent[x])  # Path compression
		return parent[x]
	
	func union(x, y):
		var x_root = find(x)
		var y_root = find(y)
		if x_root != y_root:
			parent[y_root] = x_root
			return true  # Union was successful
		return false  # x and y are already in the same set

class Leaf:
	static var room_id = 0

	# Instance variables for the leaf class
	var rect       # The rectangle representing this leaf's area
	var left_child = null
	var right_child = null
	var room = null
	var rooms = []
	var corridors = []

	func _init(_rect):
		rect = _rect

	func split() -> bool:
		if left_child != null or right_child != null:
			return false  # Already split

		var split_horizontally = randf() > 0.5

		if rect.size.x > rect.size.y and rect.size.x / rect.size.y >= 1.25:
			split_horizontally = false
		elif rect.size.y > rect.size.x and rect.size.y / rect.size.x >= 1.25:
			split_horizontally = true

		var max_size = (rect.size.y - MIN_LEAF_SIZE) if split_horizontally else (rect.size.x - MIN_LEAF_SIZE)
		if max_size <= MIN_LEAF_SIZE:
			return false  # Too small to split

		var split_distance = randf_range(MIN_LEAF_SIZE, max_size)

		if split_horizontally:
			left_child = Leaf.new(Rect2(rect.position, Vector2(rect.size.x, split_distance)))
			right_child = Leaf.new(
				Rect2(
					rect.position + Vector2(0, split_distance),
					Vector2(rect.size.x, rect.size.y - split_distance)
				)
			)
		else:
			left_child = Leaf.new(Rect2(rect.position, Vector2(split_distance, rect.size.y)))
			right_child = Leaf.new(
				Rect2(
					rect.position + Vector2(split_distance, 0),
					Vector2(rect.size.x - split_distance, rect.size.y)
				)
			)

		return true

	func create_rooms():
		if left_child != null or right_child != null:
			if left_child != null:
				left_child.create_rooms()
				self.rooms += left_child.rooms
			if right_child != null:
				right_child.create_rooms()
				self.rooms += right_child.rooms
		else:
			var room_width = randf_range(MIN_ROOM_SIZE, rect.size.x - 10)
			var room_height = randf_range(MIN_ROOM_SIZE, rect.size.y - 10)
			var room_size = Vector2(room_width, room_height)
			var room_position = rect.position + Vector2(
				randf_range(5, rect.size.x - room_width - 5),
				randf_range(5, rect.size.y - room_height - 5)
			)

			Leaf.room_id += 1
			room = Room.new(Leaf.room_id, Rect2(room_position, room_size))
			self.rooms.append(room)

	# Move the connect_rooms() function inside the Leaf class
	func connect_rooms(room1_rect: Rect2, room2_rect: Rect2) -> Array:
		var corridor_segments = []

		# Calculate edge points of both rooms towards the target room
		var point1 = get_room_edge_point_towards(room1_rect, room2_rect.position + room2_rect.size / 2)
		var point2 = get_room_edge_point_towards(room2_rect, room1_rect.position + room1_rect.size / 2)

		# Make the corridors stop just outside the room edges
		if abs(point1.x - point2.x) > abs(point1.y - point2.y):
			# Horizontal corridor
			if point1.x < point2.x:
				point2.x -= 1  # Stop before the room's right edge
			else:
				point2.x += 1  # Stop before the room's left edge
			corridor_segments.append(Rect2(point1, Vector2(point2.x - point1.x, 5)))  # Width of 5 for corridor
		else:
			# Vertical corridor
			if point1.y < point2.y:
				point2.y -= 1  # Stop before the room's bottom edge
			else:
				point2.y += 1  # Stop before the room's top edge
			corridor_segments.append(Rect2(point1, Vector2(5, point2.y - point1.y)))  # Width of 5 for corridor

		return corridor_segments


	func create_room_connections():
		var edges = []
		for i in range(self.rooms.size()):
			var room_a = self.rooms[i]
			for j in range(i + 1, self.rooms.size()):
				var room_b = self.rooms[j]
				var pos_a = room_a.rect.position + room_a.rect.size / 2
				var pos_b = room_b.rect.position + room_b.rect.size / 2
				var distance = pos_a.distance_to(pos_b)
				edges.append({"room_a": room_a, "room_b": room_b, "distance": distance})

		# Sort edges by distance
		edges.sort_custom(func(a, b):
			return a["distance"] < b["distance"]
		)

		var uf = UnionFind.new()
		for room in self.rooms:
			uf.make_set(room.id)

		# Kruskal's Algorithm to create corridors
		for edge in edges:
			var room_a_id = edge["room_a"].id
			var room_b_id = edge["room_b"].id
			if uf.union(room_a_id, room_b_id):
				var corridor = self.connect_rooms(edge["room_a"].rect, edge["room_b"].rect)
				self.corridors += corridor
				# Update connections
				edge["room_a"].connections.append(room_b_id)
				edge["room_b"].connections.append(room_a_id)


	func get_room_edge_point_towards(room_rect: Rect2, target_point: Vector2) -> Vector2:
		var center = room_rect.position + room_rect.size / 2
		var dx = target_point.x - center.x
		var dy = target_point.y - center.y
		var abs_dx = abs(dx)
		var abs_dy = abs(dy)
		var edge_point = Vector2()

		# Determine if the connection should be on the horizontal or vertical edge
		if abs_dx > abs_dy:
			# Intersection with left or right edge
			if dx > 0:
				# Right edge
				edge_point.x = room_rect.position.x + room_rect.size.x
				edge_point.y = center.y + dy * ((edge_point.x - center.x) / dx)
			else:
				# Left edge
				edge_point.x = room_rect.position.x
				edge_point.y = center.y + dy * ((edge_point.x - center.x) / dx)
		else:
			# Intersection with top or bottom edge
			if dy > 0:
				# Bottom edge
				edge_point.y = room_rect.position.y + room_rect.size.y
				edge_point.x = center.x + dx * ((edge_point.y - center.y) / dy)
			else:
				# Top edge
				edge_point.y = room_rect.position.y
				edge_point.x = center.x + dx * ((edge_point.y - center.y) / dy)

		return edge_point


func spawn_character_in_room():
	# Ensure rooms are available
	if root_leaf.rooms.size() == 0:
		print("No rooms available to spawn the player.")
		return

	# Choose a random room for the player to spawn in
	var spawn_room = root_leaf.rooms[randi_range(0, root_leaf.rooms.size() - 1)]

	# Get a random position within the room's bounds
	var spawn_x = int(randf_range(spawn_room.rect.position.x + 1, spawn_room.rect.position.x + spawn_room.rect.size.x - 1))
	var spawn_y = int(randf_range(spawn_room.rect.position.y + 1, spawn_room.rect.position.y + spawn_room.rect.size.y - 1))

	# Set the player's position (assuming the player node is named "player")
	var player = $player  # Replace with the correct path if needed
	player.position = Vector2(spawn_x, spawn_y) * 32  # Assuming 32x32 tiles

	print("Player spawned in room at position: ", player.position)


var enemy_spawn_scene = preload("res://enemy_spawn.tscn")
var wraith_scene = preload("res://wraith.tscn")

# Dictionary for enemy spawn probabilities (adjustable values)
var enemy_probabilities = {
	"Wraith": 0.3,  # 30% chance to spawn a Wraith
	"Ghost": 0.0,   # Currently set to 0% as a placeholder (set to the desired probability later)
	"Zombie": 0.0   # Currently set to 0% as a placeholder (set to the desired probability later)
}

# Dictionary to preload enemy scenes (add scenes as they become available)
var enemy_scenes = {
	"Wraith": preload("res://wraith.tscn"),
	"Ghost": null,  # Placeholder for future enemy scene
	"Zombie": null  # Placeholder for future enemy scene
}


# Function to spawn enemies in rooms
func spawn_enemies_in_rooms():
	# Ensure rooms are available
	if root_leaf.rooms.size() == 0:
		print("No rooms available to spawn enemies.")
		return

	# Reference the node where enemies should be added
	var enemy_container = self  # Using the current node as the container

	var num_rooms_to_spawn = randi_range(1, root_leaf.rooms.size())

	var rooms_to_spawn_in = root_leaf.rooms.duplicate()
	rooms_to_spawn_in.shuffle()

	for i in range(num_rooms_to_spawn):
		var spawn_room = rooms_to_spawn_in[i]
		var num_enemies = randi_range(3, 6)

		for j in range(num_enemies):
			# Get a random position within the room's bounds
			var spawn_x = int(randf_range(spawn_room.rect.position.x + 1, spawn_room.rect.position.x + spawn_room.rect.size.x - 1))
			var spawn_y = int(randf_range(spawn_room.rect.position.y + 1, spawn_room.rect.position.y + spawn_room.rect.size.y - 1))

			# Select an enemy type based on probability
			var enemy_scene = choose_enemy_based_on_probability()
			
			# Instance the enemy spawn animation scene instead of the enemy directly
			if enemy_scene != null:
				var spawn_instance = enemy_spawn_scene.instantiate()
				spawn_instance.position = Vector2(spawn_x, spawn_y) * 32
				enemy_container.add_child(spawn_instance)

				# Start the spawn process with the enemy scene to spawn after animation
				spawn_instance.start_spawn_process(enemy_scene)

				print("Spawn animation triggered in room at position: ", spawn_instance.position)
			else:
				print("Error: No valid enemy scene to instantiate.")


# Function to choose an enemy type based on the defined probabilities
func choose_enemy_based_on_probability() -> PackedScene:
	var rand_value = randf()
	var cumulative_probability = 0.0

	for enemy_type in enemy_probabilities.keys():
		cumulative_probability += enemy_probabilities[enemy_type]
		if rand_value < cumulative_probability:
			if enemy_scenes[enemy_type] != null:
				return enemy_scenes[enemy_type]
			else:
				print("Warning: Enemy scene for '%s' not yet available." % enemy_type)

	return null  # If no valid scene is found, return null


# Main _ready function
func _ready():
	boss_label = $BossLabel
	shop_label = $ShopLabel
	chest_label = $ChestLabel
	initialize_seed()
	randomize()
	generate_level()
	place_tiles()  # Place room tiles
	place_corridor_tiles()  # Place corridor tiles
	place_horizontal_path_tiles()

	# Set the room labels after the dungeon is generated
	set_room_labels()
	spawn_character_in_room()
	spawn_enemies_in_rooms()

	# Initialize the random seed
func initialize_seed(seed_value = 0):
	if seed_value == 0:
		# If no seed is provided, generate a random seed
		current_seed = randi()
	else:
		# If a seed is provided, use it (could be player input in the future)
		current_seed = seed_value
	
	# Set the seed for random number generation
	seed(current_seed)
	
	# Optionally, print the seed so the player can see and reuse it
	print("Dungeon Seed: ", current_seed)
# Generate the level using BSP
func generate_level():
	root_leaf = Leaf.new(Rect2(0, 0, MAP_WIDTH, MAP_HEIGHT))
	leaves.append(root_leaf)

	var did_split = true
	while did_split:
		did_split = false
		for leaf in leaves.duplicate():
			if leaf.left_child == null and leaf.right_child == null:
				if leaf.rect.size.x > MAX_LEAF_SIZE or leaf.rect.size.y > MAX_LEAF_SIZE or randf() > 0.8:
					if leaf.split():
						leaves.append(leaf.left_child)
						leaves.append(leaf.right_child)
						did_split = true

	root_leaf.create_rooms()
	root_leaf.create_room_connections()
	#spawn_enemies_in_rooms()

func set_room_labels():
	# Ensure there are enough rooms generated to place labels
	if root_leaf.rooms.size() < 3:
		print("Not enough rooms generated to assign all labels.")
		return
	
	# Randomly pick 3 unique rooms for Boss, Shop, and Chest
	var boss_room = get_random_room()
	var shop_room = get_random_room([boss_room])
	var chest_room = get_random_room([boss_room, shop_room])

	# Set the Boss Room label
	var boss_position = get_randomized_room_position(boss_room)
	boss_label.text = "Boss Room: ID %s" % boss_room.id
	boss_label.position = boss_position + Vector2(0, -20)  # Slightly above the random position

	# Set the Shop Room label
	var shop_position = get_randomized_room_position(shop_room)
	shop_label.text = "Shop Room: ID %s" % shop_room.id
	shop_label.position = shop_position + Vector2(0, -20)  # Slightly above the random position

	# Set the Chest Room label
	var chest_position = get_randomized_room_position(chest_room)
	chest_label.text = "Chest Room: ID %s" % chest_room.id
	chest_label.position = chest_position + Vector2(0, -20)  # Slightly above the random position

# Function to get a random room, optionally excluding some rooms
func get_random_room(exclude=[]):
	var available_rooms = []  # Create a new list for available rooms
	
	# Add rooms to the available list if they are not in the exclude list
	for room in root_leaf.rooms:
		if not exclude.has(room):
			available_rooms.append(room)
	
	# Return a random room from the available list
	return available_rooms[randi_range(0, available_rooms.size() - 1)]

# Function to get a random position within the bounds of the room
func get_randomized_room_position(room) -> Vector2:
	# Get room bounds in tile coordinates
	var room_position = room.rect.position
	var room_size = room.rect.size
	
	# Randomize a position within the room's bounds
	var random_x = randf_range(room_position.x + 5, room_position.x + room_size.x - 5)  # Add padding of 5 tiles to avoid walls
	var random_y = randf_range(room_position.y + 5, room_position.y + room_size.y - 5)
	
	# Convert the random tile coordinates to world coordinates
	return map_to_local(Vector2(random_x, random_y))

# Example logic to check room types
func room_is_boss_room(room):
	return room.id == 1  # Assume the first room generated is the Boss Room

func room_is_shop_room(room):
	return room.id == 2  # Assume the second room generated is the Shop Room

func room_is_chest_room(room):
	return room.id == 3  # Assume the third room generated is the Chest Room

func is_corridor_connected(x, y) -> bool:
	# Function to check if there's a corridor connected to this position
	for corridor in root_leaf.corridors:
		var corridor_start = corridor.position
		var corridor_end = corridor.position + corridor.size

		# Adjust the check to account for the 2-tile wide corridor
		var x_offset = 2
		var y_offset = 2

		# Horizontal corridors
		if corridor.size.x > corridor.size.y:
			if (x >= int(corridor_start.x) - x_offset and x <= int(corridor_end.x) + x_offset) and y == int(corridor_start.y):
				return true
		
		# Vertical corridors
		else:
			if (y >= int(corridor_start.y) - y_offset and y <= int(corridor_end.y) + y_offset) and x == int(corridor_start.x):
				return true

	return false


# Function to handle wall removal and floor placement for corridor connections
func replace_walls_with_floor(x, y, horizontal=true):
	if horizontal:
		# Horizontal corridors: Replace 5 tiles vertically (center and 2 above/below)
		for y_offset in range(-2, 3):
			set_cell(0, Vector2i(x, y + y_offset), 1, Vector2i(7, 3))  # Floor tile
	else:
		# Vertical corridors: Replace 5 tiles horizontally (center and 2 left/right)
		for x_offset in range(-2, 3):
			set_cell(0, Vector2i(x + x_offset, y), 1, Vector2i(7, 3))  # Floor tile

func place_tiles():
	var layer = 0  # Layer for both walls and floors

	# Atlas floor tile coordinates (3,3) through (10,5)
	var floor_pattern_start = Vector2i(3, 3)
	var floor_pattern_end = Vector2i(10, 5)

	# Calculate the width and height of the atlas matrix
	var atlas_width = floor_pattern_end.x - floor_pattern_start.x + 1
	var atlas_height = floor_pattern_end.y - floor_pattern_start.y + 1

	# Place floor and walls for each room
	for room in root_leaf.rooms:
		# Room coordinates
		var x_start = int(floor(room.rect.position.x))
		var y_start = int(floor(room.rect.position.y))
		var x_end = int(floor(room.rect.position.x + room.rect.size.x))
		var y_end = int(floor(room.rect.position.y + room.rect.size.y))

		# Place floor tiles inside the room, traversing the atlas matrix in a repeating pattern
		for x in range(x_start, x_end):
			for y in range(y_start, y_end):
				# Calculate the current tile in the atlas based on the x and y offsets
				var atlas_x = floor_pattern_start.x + (x - x_start) % atlas_width
				var atlas_y = floor_pattern_start.y + (y - y_start) % atlas_height

				# Place the current floor tile from the atlas
				set_cell(layer, Vector2i(x, y), 1, Vector2i(atlas_x, atlas_y))

		# Place 2-tile thick walls around the room perimeter

		# Top and Bottom walls
		for x in range(x_start - 2, x_end + 2):
			# Top wall (2 tiles thick)
			set_cell(layer, Vector2i(x, y_start - 1), 0, Vector2i(7, 1))  # First row of top wall
			set_cell(layer, Vector2i(x, y_start - 2), 0, Vector2i(7, 0))  # Second row of top wall
			# Bottom wall (2 tiles thick)
			set_cell(layer, Vector2i(x, y_end), 0, Vector2i(7, 7))  # First row of bottom wall
			set_cell(layer, Vector2i(x, y_end + 1), 0, Vector2i(7, 8))  # Second row of bottom wall

		# Left and Right walls
		for y in range(y_start - 1, y_end + 2):
			# Left wall (2 tiles thick)
			set_cell(layer, Vector2i(x_start - 2, y), 0, Vector2i(0, 4))  # First column of left wall
			set_cell(layer, Vector2i(x_start - 1, y), 0, Vector2i(1, 4))  # Second column of left wall
			# Right wall (2 tiles thick)
			set_cell(layer, Vector2i(x_end, y), 0, Vector2i(12, 4))  # First column of right wall
			set_cell(layer, Vector2i(x_end + 1, y), 0, Vector2i(13, 4))  # Second column of right wall

		# Place corner tiles (4 tiles per corner)
		# Top-left corner
		set_cell(layer, Vector2i(x_start - 2, y_start - 1), 0, Vector2i(0, 1))
		set_cell(layer, Vector2i(x_start - 1, y_start - 1), 0, Vector2i(1, 1))
		set_cell(layer, Vector2i(x_start - 2, y_start - 2), 0, Vector2i(0, 0))
		set_cell(layer, Vector2i(x_start - 1, y_start - 2), 0, Vector2i(1, 0))

		# Top-right corner
		set_cell(layer, Vector2i(x_end, y_start - 1), 0, Vector2i(12, 1))
		set_cell(layer, Vector2i(x_end + 1, y_start - 1), 0, Vector2i(13, 1))
		set_cell(layer, Vector2i(x_end, y_start - 2), 0, Vector2i(12, 0))
		set_cell(layer, Vector2i(x_end + 1, y_start - 2), 0, Vector2i(13, 0))

		# Bottom-left corner
		set_cell(layer, Vector2i(x_start - 2, y_end), 0, Vector2i(0, 7))
		set_cell(layer, Vector2i(x_start - 1, y_end), 0, Vector2i(1, 7))
		set_cell(layer, Vector2i(x_start - 2, y_end + 1), 0, Vector2i(0, 8))
		set_cell(layer, Vector2i(x_start - 1, y_end + 1), 0, Vector2i(1, 8))

		# Bottom-right corner
		set_cell(layer, Vector2i(x_end, y_end), 0, Vector2i(12, 7))
		set_cell(layer, Vector2i(x_end + 1, y_end), 0, Vector2i(13, 7))
		set_cell(layer, Vector2i(x_end, y_end + 1), 0, Vector2i(12, 8))
		set_cell(layer, Vector2i(x_end + 1, y_end + 1), 0, Vector2i(13, 8))


# Function to place corridor tiles using atlas coordinates, with walls and corner tiles
# Function to handle wall removal and floor placement for corridor connections
func replace_walls_with_floor_at_connection(x, y, is_horizontal=true):
	if is_horizontal:
		# Horizontal corridors: Remove walls and replace 5 tiles vertically (center and 2 above/below)
		for y_offset in range(-2, 3):
			set_cell(0, Vector2i(x, y + y_offset), 1, Vector2i(7, 3))  # Floor tile
	else:
		# Vertical corridors: Remove walls and replace 5 tiles horizontally (center and 2 left/right)
		for x_offset in range(-2, 3):
			set_cell(0, Vector2i(x + x_offset, y), 1, Vector2i(7, 3))  # Floor tile
# Function to place horizontal path tiles using atlas coordinates, with walls and corner tiles
# Function to place horizontal path tiles and walls using atlas coordinates
# Function to place horizontal path tiles and walls on the Path layer (layer 2)
func place_horizontal_path_tiles():
	var layer = 2  # Path layer ID for all path-related tiles

	# Iterate over the horizontal paths and place tiles
	for corridor in root_leaf.corridors:
		var x_start = int(floor(corridor.position.x))
		var y_start = int(floor(corridor.position.y))
		var x_end = int(floor(corridor.position.x + corridor.size.x))

		# Only process horizontal corridors
		if abs(x_end - x_start) > abs(corridor.size.y):
			# Handle both floor and wall placements for the path on this layer
			for x in range(x_start, x_end):
				# First place the floor tiles for the path (layer 2 only)
				for y_offset in range(-2, 3):  # Path should still be 5 tiles wide (2 above and 2 below the centerline)
					set_cell(layer, Vector2i(x, y_start + y_offset), 1, Vector2i(7, 3))  # Floor tile from the atlas

					# Handle the placement of corner tiles for the path
					if x == x_start or x == x_end:
						# Top-left corner (x_start) and Top-right corner (x_end)
						if y_offset == -2:
							if x == x_start:
								set_cell(layer, Vector2i(x, y_start + y_offset), 1, Vector2i(5, 9))  # Top-left corner
								set_cell(layer, Vector2i(x + 1, y_start + y_offset), 1, Vector2i(6, 9))
							elif x == x_end:
								set_cell(layer, Vector2i(x, y_start + y_offset), 1, Vector2i(13, 9))  # Top-right corner
								set_cell(layer, Vector2i(x + 1, y_start + y_offset), 1, Vector2i(14, 9))

						# Bottom-left corner (x_start) and Bottom-right corner (x_end)
						if y_offset == 2:
							if x == x_start:
								set_cell(layer, Vector2i(x, y_start + y_offset), 1, Vector2i(5, 14))  # Bottom-left corner
								set_cell(layer, Vector2i(x + 1, y_start + y_offset), 1, Vector2i(6, 14))
							elif x == x_end:
								set_cell(layer, Vector2i(x, y_start + y_offset), 1, Vector2i(13, 14))  # Bottom-right corner
								set_cell(layer, Vector2i(x + 1, y_start + y_offset), 1, Vector2i(14, 14))

				# Now handle the placement of wall tiles inside the path
				for y_offset in [-2, 2]:  # Walls will only be placed at -2 (top) and 2 (bottom) y-offsets
					if y_offset == -2:
						# Top walls: Left and right sides of the path
						if x == x_start + 2 or x == x_start + 3:  # Left side top wall
							set_cell(layer, Vector2i(x, y_start + y_offset), 0, Vector2i(7, 10))  # Left wall segment
							set_cell(layer, Vector2i(x + 1, y_start + y_offset), 0, Vector2i(8, 10))
						elif x == x_end - 3 or x == x_end - 2:  # Right side top wall
							set_cell(layer, Vector2i(x, y_start + y_offset), 0, Vector2i(11, 10))  # Right wall segment
							set_cell(layer, Vector2i(x + 1, y_start + y_offset), 0, Vector2i(12, 10))
						elif x == x_start + 4:  # Middle wall tile between the left and right walls
							set_cell(layer, Vector2i(x, y_start + y_offset), 0, Vector2i(9, 10))

					if y_offset == 2:
						# Bottom walls: Left and right sides of the path
						if x == x_start + 2 or x == x_start + 3:  # Left side bottom wall
							set_cell(layer, Vector2i(x, y_start + y_offset), 0, Vector2i(7, 14))  # Left wall segment
							set_cell(layer, Vector2i(x + 1, y_start + y_offset), 0, Vector2i(8, 14))
						elif x == x_end - 3 or x == x_end - 2:  # Right side bottom wall
							set_cell(layer, Vector2i(x, y_start + y_offset), 0, Vector2i(11, 14))  # Right wall segment
							set_cell(layer, Vector2i(x + 1, y_start + y_offset), 0, Vector2i(12, 14))
						elif x == x_start + 4:  # Middle wall tile between the left and right walls
							set_cell(layer, Vector2i(x, y_start + y_offset), 0, Vector2i(9, 14))


# Function to place only the walls and corner tiles for corridors
# Function to place corridor tiles (path, walls, and corners) only on Layer 2
func place_corridor_tiles():
	var layer = 2  # Only use Layer 2 for all corridor-related tiles

	for corridor in root_leaf.corridors:
		var x_start = int(floor(corridor.position.x))
		var y_start = int(floor(corridor.position.y))
		var x_end = int(floor(corridor.position.x + corridor.size.x))
		var y_end = int(floor(corridor.position.y + corridor.size.y))

		# Determine if this segment is horizontal or vertical
		var is_horizontal = abs(x_end - x_start) > abs(y_end - y_start)

		if is_horizontal:
			# Horizontal corridor: Place top and bottom walls, floors, and path tiles on Layer 2

			# Place path tiles for the corridor (5 tiles wide, centered)
			for x in range(x_start, x_end + 1):  # Include the last column by using x_end + 1
				# Place the centerline floor tiles (path floor tiles)
				set_cell(layer, Vector2i(x, y_start), 2, Vector2i(7, 3))  # Path floor tile (centerline)

				# Place additional path tiles above and below centerline
				for y_offset in range(-2, 3):  # Path should be 5 tiles wide (2 above and 2 below the centerline)
					set_cell(layer, Vector2i(x, y_start + y_offset), 2, Vector2i(7, 3))  # Path floor tiles

			# Wall placement for top walls (lifted up by 1 row)
			# (7,10 to 8,11), (11,10 to 12,11) - Ensure all columns are placed correctly
			set_cell(layer, Vector2i(x_start + 2, y_start - 4), 2, Vector2i(7, 10))  # Top-left wall (7,10) lifted up
			set_cell(layer, Vector2i(x_start + 2, y_start - 3), 2, Vector2i(7, 11))  # Tile below 7,10 (7,11)
			set_cell(layer, Vector2i(x_start + 3, y_start - 4), 2, Vector2i(8, 10))  # Next to top-left (8,10) lifted up
			set_cell(layer, Vector2i(x_start + 3, y_start - 3), 2, Vector2i(8, 11))  # Tile below 8,10 (8,11)

			set_cell(layer, Vector2i(x_end - 2, y_start - 4), 2, Vector2i(12, 10))  # Top-right wall (12,10) lifted up
			set_cell(layer, Vector2i(x_end - 2, y_start - 3), 2, Vector2i(12, 11))  # Tile below 12,10 (12,11)
			set_cell(layer, Vector2i(x_end - 3, y_start - 4), 2, Vector2i(11, 10))  # Next to top-right (11,10) lifted up
			set_cell(layer, Vector2i(x_end - 3, y_start - 3), 2, Vector2i(11, 11))  # Tile below 11,10 (11,11)

			# Repeatable middle wall tiles for the top
			for x in range(x_start + 4, x_end - 4):
				set_cell(layer, Vector2i(x, y_start - 4), 2, Vector2i(9, 10))  # Middle repeated wall tile (9,10)
				set_cell(layer, Vector2i(x, y_start - 3), 2, Vector2i(9, 11))  # Middle repeated wall tile (9,11)

			# Wall placement for bottom walls (7,14 to 8,15), (11,14 to 12,15)
			set_cell(layer, Vector2i(x_start + 2, y_start + 3), 2, Vector2i(7, 14))  # Bottom-left wall (7,14)
			set_cell(layer, Vector2i(x_start + 2, y_start + 4), 2, Vector2i(7, 15))  # Tile below 7,14 (7,15)
			set_cell(layer, Vector2i(x_start + 3, y_start + 3), 2, Vector2i(8, 14))  # Next to bottom-left (8,14)
			set_cell(layer, Vector2i(x_start + 3, y_start + 4), 2, Vector2i(8, 15))  # Tile below 8,14 (8,15)

			set_cell(layer, Vector2i(x_end - 2, y_start + 3), 2, Vector2i(12, 14))  # Bottom-right wall (12,14)
			set_cell(layer, Vector2i(x_end - 2, y_start + 4), 2, Vector2i(12, 15))  # Tile below 12,14 (12,15)
			set_cell(layer, Vector2i(x_end - 3, y_start + 3), 2, Vector2i(11, 14))  # Next to bottom-right (11,14)
			set_cell(layer, Vector2i(x_end - 3, y_start + 4), 2, Vector2i(11, 15))  # Tile below 11,14 (11,15)

			# Repeatable middle wall tiles for the bottom
			for x in range(x_start + 4, x_end - 4):
				set_cell(layer, Vector2i(x, y_start + 3), 2, Vector2i(9, 14))  # Middle repeated wall tile (9,14)
				set_cell(layer, Vector2i(x, y_start + 4), 2, Vector2i(9, 15))  # Middle repeated wall tile (9,15)

			# Corner tile placement for the start and end of the horizontal corridor
			set_cell(layer, Vector2i(x_start, y_start - 4), 2, Vector2i(12, 1))  # Top-left corner lifted
			set_cell(layer, Vector2i(x_start, y_start + 3), 2, Vector2i(12, 7))  # Bottom-left corner
			set_cell(layer, Vector2i(x_end, y_start - 4), 2, Vector2i(1, 1))  # Top-right corner lifted
			set_cell(layer, Vector2i(x_end, y_start + 3), 2, Vector2i(1, 7))  # Bottom-right corner

		else:
			# Vertical corridor: Place left and right walls, floors, and path tiles on Layer 2
			for y in range(y_start, y_end + 1):  # Include the last row by using y_end + 1
				# Place the centerline floor tiles (path floor tiles) for the corridor
				set_cell(layer, Vector2i(x_start, y), 2, Vector2i(7, 3))  # Path floor tile (centerline)

				# Place additional path tiles to widen the corridor (left and right of the centerline)
				for x_offset in range(-2, 3):  # Path should be 5 tiles wide (2 left and 2 right of centerline)
					set_cell(layer, Vector2i(x_start + x_offset, y), 2, Vector2i(7, 3))  # Path floor tiles

			# Wall placement for left and right walls in the vertical corridor (use your provided coordinates)
			set_cell(layer, Vector2i(x_start - 3, y_start), 2, Vector2i(1, 7))  # Bottom-left corner at the top
			set_cell(layer, Vector2i(x_start + 3, y_start), 2, Vector2i(12, 7))  # Bottom-right corner at the top
			set_cell(layer, Vector2i(x_start - 3, y_end), 2, Vector2i(1, 1))  # Top-left corner at the bottom
			set_cell(layer, Vector2i(x_start + 3, y_end), 2, Vector2i(12, 1))  # Top-right corner at the bottom




# Camera movement and zooming using WASD and -/= keys
func _process(delta):
	var camera = $Camera2D
	var move_vector = Vector2()

	# Camera movement with WASD
	if Input.is_key_pressed(KEY_W):  # Move up
		move_vector.y -= 1
	if Input.is_key_pressed(KEY_A):  # Move left
		move_vector.x -= 1
	if Input.is_key_pressed(KEY_S):  # Move down
		move_vector.y += 1
	if Input.is_key_pressed(KEY_D):  # Move right
		move_vector.x += 1
	
	# Apply the movement
	camera.position += move_vector * CAMERA_SPEED * delta

	# Camera zooming with - and =
	if Input.is_key_pressed(KEY_9):  # Zoom out
		camera.zoom += Vector2(ZOOM_SPEED, ZOOM_SPEED) * delta
	if Input.is_key_pressed(KEY_0):  # Zoom in (using = key)
		camera.zoom -= Vector2(ZOOM_SPEED, ZOOM_SPEED) * delta

	# Clamp zoom to avoid excessive zoom in/out (you can adjust these limits)
	camera.zoom.x = clamp(camera.zoom.x, 0.2, 5)
	camera.zoom.y = clamp(camera.zoom.y, 0.2, 5)

# Handling direct key presses in _input(event) using keycode (Godot 4)
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				$Camera2D.position.y -= CAMERA_SPEED * get_process_delta_time()
			KEY_A:
				$Camera2D.position.x -= CAMERA_SPEED * get_process_delta_time()
			KEY_S:
				$Camera2D.position.y += CAMERA_SPEED * get_process_delta_time()
			KEY_D:
				$Camera2D.position.x += CAMERA_SPEED * get_process_delta_time()
