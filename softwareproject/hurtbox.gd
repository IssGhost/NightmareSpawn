extends Area2D
class_name HurtBox

@export var target : CharacterBody2D

func _on_area_entered(area : Area2D):
	# Debug print to check when this function is called
	print("Area entered: ", area.name)

	# Check if the area has a get_damage_amount method and handle damage properly
	if area.has_method("get_damage_amount"):
		var damage = area.get_damage_amount()
		print("Damage amount: ", damage)
		target.take_damage(damage)
	else:
		print("Error: The area does not have a get_damage_amount method")
