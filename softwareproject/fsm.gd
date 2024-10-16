extends Node
class_name FiniteStateMachine

@export var current_state : State
@export var animator : AnimationPlayer
@export var actor : CharacterBody2D
@export var pivot : Marker2D

var previous_state : State

var states = {}

func _ready():
	# Ensure the actor is assigned to all states in the FSM
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.transition.connect(transition)
			
			# Assign the actor, animator, and pivot to the child states
			child.actor = actor
			child.animator = animator
			child.pivot = pivot

	# Start with the initial state if it's set
	if current_state:
		change_state(previous_state, current_state)


func transition(new_state: String):
	previous_state = current_state
	current_state.is_current = false
	change_state(previous_state, states[new_state])

func change_state(_previous_state: State, new_state : State):
	if new_state is State:
		if current_state:
			print("Exiting state: ", current_state.name)
			current_state.exit_state()

		print("Entering state: ", new_state.name)
		new_state.enter_state(previous_state)
		new_state.is_current = true
		current_state = new_state


func _process(delta: float):
	if current_state:
		current_state.frame_update(delta)

func _physics_process(delta: float):
	if current_state:
		current_state.physics_update(delta)
