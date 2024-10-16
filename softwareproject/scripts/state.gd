extends Node
class_name State

var previous_state : State
var is_current : bool = false

signal transition(new_state : int)

var actor : CharacterBody2D
var animator : AnimationPlayer
var pivot : Marker2D

@onready var state_machine : FiniteStateMachine = get_node_or_null("..") as FiniteStateMachine

func enter_state(_prev_state : State) -> void:
	pass
	
func exit_state() -> void:
	pass
	
func frame_update(_delta : float) -> void:
	pass
	
func physics_update(_delta : float) -> void:
	pass

func animation_finished() -> void:
	pass
