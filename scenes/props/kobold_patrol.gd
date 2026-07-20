extends Node2D
## Wraps a KoboldEnemy with a Path2D patrol route.
## Drop this into any level - the Kobold will patrol between the waypoints.
## When the player enters detection range, it will chase instead.

@export var patrol_speed: float = 60.0
@export var detection_range: float = 180.0

@onready var kobold: Node2D = $KoboldEnemy
@onready var path: Path2D = $PatrolPath

func _ready():
	if not kobold or not path:
		push_warning("KoboldPatrol: Missing KoboldEnemy or PatrolPath")
		return
	
	# Wait for the enemy to fully initialize
	await kobold.ready
	
	# Set properties on the kobold
	kobold.set("detection_range", detection_range)
	kobold.set("max_speed", patrol_speed)
	
	# Set up patrol state in the enemy's state machine
	_setup_patrol_state()

func _setup_patrol_state():
	var state_machine = kobold.get_node_or_null("EnemyStates")
	if not state_machine:
		return
	
	# Create StatePath and add it to the state machine
	var state_path_script = preload("res://scripts/state_machine/states/state_path.gd")
	var patrol_state = state_path_script.new()
	patrol_state.name = "patrol"
	patrol_state.path = path
	patrol_state.repeats = 0  # Repeat indefinitely
	patrol_state.distance_threshold = 4.0
	state_machine.add_child(patrol_state)
	patrol_state.owner = kobold
	
	# Enable patrol state after setup
	await get_tree().physics_frame
	if is_instance_valid(state_machine) and is_instance_valid(patrol_state):
		state_machine.enable_state(patrol_state)
