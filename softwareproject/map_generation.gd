extends Node2D

# Constants
const MAP_WIDTH = 1024
const MAP_HEIGHT = 768
const MIN_LEAF_SIZE = 128
const MAX_LEAF_SIZE = 256
const MIN_ROOM_SIZE = 64

# Global variables
var leaves = []
var root_leaf

# Room class
class Room:
	var id
	var rect
	var connections = []

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
	# Static variable to keep track of room IDs
	static var room_id = 0

	var rect       # The rectangle representing this leaf's area
	var left_child = null
	var right_child = null
	var room = null

	# Instance variables to store rooms and corridors
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

	func create_room_connections():
		# Create a list of all possible edges
		var edges = []
		for i in range(self.rooms.size()):
			var room_a = self.rooms[i]
			for j in range(i + 1, self.rooms.size()):
				var room_b = self.rooms[j]
				var pos_a = room_a.rect.position + room_a.rect.size / 2
				var pos_b = room_b.rect.position + room_b.rect.size / 2
				var distance = pos_a.distance_to(pos_b)
				edges.append({ "room_a": room_a, "room_b": room_b, "distance": distance })
		
		# Sort edges by distance
		edges.sort_custom(func(a, b):
			return a["distance"] < b["distance"]
		)
		
		# Initialize Union-Find structure
		var uf = UnionFind.new()
		for room in self.rooms:
			uf.make_set(room.id)
		
		# Kruskal's Algorithm to build the MST
		for edge in edges:
			var room_a_id = edge["room_a"].id
			var room_b_id = edge["room_b"].id
			if uf.union(room_a_id, room_b_id):
				# Rooms were not connected, now connect them
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

	func connect_rooms(room1_rect: Rect2, room2_rect: Rect2) -> Array:
		var corridor_segments = []
		var point1 = self.get_room_edge_point_towards(room1_rect, room2_rect.position + room2_rect.size / 2)
		var point2 = self.get_room_edge_point_towards(room2_rect, room1_rect.position + room1_rect.size / 2)

		if randf() > 0.5:
			# Horizontal then vertical
			corridor_segments.append(Rect2(point1, Vector2(point2.x - point1.x, 5)))
			corridor_segments.append(Rect2(Vector2(point2.x, point1.y), Vector2(5, point2.y - point1.y)))
		else:
			# Vertical then horizontal
			corridor_segments.append(Rect2(point1, Vector2(5, point2.y - point1.y)))
			corridor_segments.append(Rect2(Vector2(point1.x, point2.y), Vector2(point2.x - point1.x, 5)))
		return corridor_segments

# End of the 'Leaf' class

func _ready():
	randomize()
	generate_level()
	queue_redraw()

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

func _draw():
	# Draw rooms
	for room in root_leaf.rooms:
		draw_rect(room.rect, Color(0, 1, 0))  # Green color for rooms

	# Draw corridors
	for segment in root_leaf.corridors:
		draw_rect(segment, Color(1, 1, 0))  # Yellow color for corridors

func _input(event):
	pass  # Input handling not needed at this point
