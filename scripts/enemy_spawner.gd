@icon("res://icons/TargetManager.svg")
extends Node2D
class_name EnemySpawner

## Spawns enemies from a PackedScene, optionally on a timer or when the player is near.

@export_group("Enemy Settings")
## The enemy scene to spawn (e.g. kobold_enemy.tscn, bat_enemy.tscn).
@export var enemy_scene: PackedScene
## Optional patrol path for spawned enemies to follow. The enemy will patrol between waypoints.
@export var patrol_path: Path2D = null

@export_group("Spawn Settings")
## If > 0, spawns enemies repeatedly at this interval (seconds). If 0, spawns once.
@export var spawn_interval: float = 0.0
## Initial delay before the first spawn (seconds).
@export var initial_delay: float = 0.0
## Maximum number of enemies that can exist at once. 0 = unlimited.
@export var max_concurrent: int = 0
## Maximum total spawns. 0 = unlimited.
@export var max_total_spawns: int = 0
## Random offset radius from the spawner position. Enemies spawn within this radius.
@export var spawn_radius: float = 0.0

@export_group("Trigger Settings")
## If true, starts spawning automatically when the scene loads.
@export var auto_start: bool = true
## If > 0, only starts spawning when the player is within this range.
@export var player_detection_range: float = 0.0

@onready var _spawn_timer: Timer = $SpawnTimer

var _spawned_enemies: Array[Node] = []
var _total_spawns: int = 0
var _active: bool = false
var _player_ref: Node = null

func _ready():
	if not enemy_scene:
		push_warning("EnemySpawner: No enemy scene assigned. Spawner will not work.")
		return
	
	if auto_start:
		_activate()

func _process(_delta):
	if _active and player_detection_range > 0.0 and not _is_player_in_range():
		_deactivate()
	elif not _active and player_detection_range > 0.0 and _is_player_in_range():
		_activate()

func _is_player_in_range() -> bool:
	if not _player_ref:
		_player_ref = Globals.get_player(1)
	if not is_instance_valid(_player_ref):
		return false
	return global_position.distance_to(_player_ref.global_position) <= player_detection_range

func _activate():
	if _active:
		return
	_active = true
	
	if initial_delay > 0:
		await get_tree().create_timer(initial_delay).timeout
		if not _active:
			return
	
	_spawn_enemy()
	
	if spawn_interval > 0:
		_spawn_timer.wait_time = spawn_interval
		_spawn_timer.start()

func _deactivate():
	_active = false
	_spawn_timer.stop()

func _on_spawn_timer_timeout():
	_spawn_enemy()

func _spawn_enemy():
	if not enemy_scene:
		return
	
	# Check max total spawns
	if max_total_spawns > 0 and _total_spawns >= max_total_spawns:
		_spawn_timer.stop()
		return
	
	# Clean up dead enemies
	_spawned_enemies = _spawned_enemies.filter(func(e): return is_instance_valid(e))
	
	# Check max concurrent
	if max_concurrent > 0 and _spawned_enemies.size() >= max_concurrent:
		return
	
	# Spawn the enemy
	var enemy = enemy_scene.instantiate()
	
	# Position with optional random offset
	var spawn_pos = global_position
	if spawn_radius > 0:
		spawn_pos += Vector2(randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius))
	enemy.global_position = spawn_pos
	
	# Add to the scene tree
	get_tree().current_scene.add_child(enemy)
	
	# Set up patrol path if provided
	if patrol_path and enemy.has_node("EnemyStates"):
		var state_machine = enemy.get_node("EnemyStates")
		_add_patrol_state(enemy, state_machine)
	
	# Track and clean up on death
	_spawned_enemies.append(enemy)
	_total_spawns += 1
	
	# Listen for death to free the slot
	if enemy.has_node("HealthController"):
		enemy.get_node("HealthController").hp_changed.connect(_on_enemy_hp_changed.bind(enemy))

func _on_enemy_hp_changed(_hp: int, enemy: Node):
	if not is_instance_valid(enemy):
		return
	var health_controller = enemy.get_node("HealthController")
	if health_controller and health_controller.hp <= 0:
		# Will be freed by the death state - just remove from tracking
		_spawned_enemies = _spawned_enemies.filter(func(e): return e != enemy)

func _add_patrol_state(enemy: Node, state_machine: Node):
	# Check if StatePath already exists
	if state_machine.has_node("patrol"):
		return
	
	# Create StatePath and add it to the state machine
	var state_path_script = preload("res://scripts/state_machine/states/state_path.gd")
	var patrol_state = state_path_script.new()
	patrol_state.name = "patrol"
	patrol_state.path = patrol_path
	patrol_state.repeats = 0  # Repeat indefinitely
	patrol_state.distance_threshold = 4.0
	state_machine.add_child(patrol_state)
	patrol_state.owner = enemy
	
	# Enable patrol state after the state machine initializes
	await get_tree().physics_frame
	if is_instance_valid(state_machine) and is_instance_valid(patrol_state):
		state_machine.enable_state(patrol_state)

## Public method to manually trigger a spawn (e.g. from a lever or trigger zone).
func trigger_spawn():
	_spawn_enemy()

## Public method to start the spawner.
func start():
	_activate()

## Public method to stop the spawner.
func stop():
	_deactivate()

## Public method to get the current count of alive spawned enemies.
func get_active_enemy_count() -> int:
	_spawned_enemies = _spawned_enemies.filter(func(e): return is_instance_valid(e))
	return _spawned_enemies.size()
