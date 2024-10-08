extends Node2D

# Reference to the corridors array generated in the main script
var corridors = []

func _draw():
	# Draw corridors between rooms as lines
	for corridor in corridors:
		draw_line(corridor["start"], corridor["end"], Color(0, 1, 0), 3)  # Green lines for corridors
