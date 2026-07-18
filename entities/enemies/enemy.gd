extends CharacterEntity
class_name Enemy

## Basic enemy AI that wanders and chases the player when in range.

@export var detection_range := 150.0
@export var attack_range := 30.0
@export var wander_time_range := Vector2(1.0, 3.0)

@onready var state_machine_node: Node = $EnemyStates

var player_ref: PlayerEntity = null
var wander_direction := Vector2.ZERO
var wander_timer := 0.0

func _ready():
	super._ready()
	# Find player in the scene
	player_ref = Globals.get_player(1)

func _process(delta):
	super._process(delta)
	if health_controller.hp <= 0:
		return
		
	if not player_ref or player_ref.health_controller.hp <= 0:
		_wander_behavior(delta)
		return
		
	var distance = global_position.distance_to(player_ref.global_position)
	
	if distance <= attack_range:
		_attack_behavior()
	elif distance <= detection_range:
		_chase_behavior()
	else:
		_wander_behavior(delta)

func _wander_behavior(delta):
	wander_timer -= delta
	if wander_timer <= 0:
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		wander_timer = randf_range(wander_time_range.x, wander_time_range.y)
	move(wander_direction)

func _chase_behavior():
	var direction = global_position.direction_to(player_ref.global_position)
	move(direction)

func _attack_behavior():
	face_towards(player_ref.global_position)
	attack()