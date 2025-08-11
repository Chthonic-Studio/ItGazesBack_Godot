class_name PlayerStateMachine extends Node

var states : Array [ State ]
var prev_state : State
var current_state : State
var initial_state_name : String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	change_state( current_state.process( delta ) )

func _physics_process(delta: float) -> void:
	if current_state:
		change_state( current_state.physics(delta) )

func _unhandled_input(event: InputEvent) -> void:
	change_state( current_state.handle_input( event ) )

func set_initial_state(state_name: String) -> void:
	initial_state_name = state_name

func initialize( _player : Player ) -> void:
	states = [ ]
	
	for c in get_children():
		if c is State:
			states.append(c)
			c.player = _player # Make sure player is assigned before entering state
	
	if states.size() == 0:
		return
	
	# If an initial state was specified, use it. Otherwise, default to the first child.
	if initial_state_name != "" and has_node(initial_state_name):
		current_state = get_node(initial_state_name)
	else:
		current_state = states[0]
		
	states[0].state_machine = self
	
	for state in states:
		state.init()
	
	current_state.enter()
	process_mode = Node.PROCESS_MODE_INHERIT

func change_state( new_state : State ) -> void:
	if new_state == null || new_state == current_state:
		return
	
	if current_state:
		current_state.exit()
	
	prev_state = current_state
	current_state = new_state
	current_state.enter()

# This function allows the player to request an animation update.
func update_animation() -> void:
	if current_state:
		current_state.update_animation()
