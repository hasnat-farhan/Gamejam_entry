extends Node2D
## Wraps any NPC with a Path2D patrol route.
## Drop this into any level - the NPC will patrol between waypoints.
## When the player gets close enough to interact, the NPC stops and faces the player.
## After interaction ends, patrol resumes.

@export var patrol_speed: float = 40.0  ## Movement speed along the path (px/sec)
@export var pause_time: float = 1.0     ## Pause at each waypoint (seconds)
@export var stop_distance: float = 64.0 ## Stop patrolling when player is within this range
@export var has_walk_animation: bool = false  ## Switch to walk animation while moving? (requires "walk" anim on the NPC)

@onready var npc: Node2D = $NPC
@onready var path: Path2D = $PatrolPath

var _tween: Tween = null
var _is_patrolling: bool = false
var _is_paused: bool = false
var _current_progress: float = 0.0
var _player_ref: Node = null

func _ready():
	if not npc or not path or not path.curve:
		push_warning("NPCPatrol: Missing NPC, PatrolPath, or curve points")
		return
	
	# Start patrolling after a short delay
	await get_tree().physics_frame
	_start_patrol()

func _process(_delta):
	if stop_distance <= 0 or not _is_patrolling:
		return
		
	if not _player_ref:
		_player_ref = Globals.get_player(1)
	
	if is_instance_valid(_player_ref):
		var dist = npc.global_position.distance_to(_player_ref.global_position)
		if dist < stop_distance and not _is_paused:
			_pause_patrol()
		elif dist >= stop_distance and _is_paused:
			_resume_patrol()

func _start_patrol():
	if _is_patrolling:
		return
	
	_is_patrolling = true
	_is_paused = false
	_current_progress = 0.0
	_move_along_path()

func _move_along_path():
	if not path or not path.curve:
		return
	
	var curve = path.curve
	var total_length = curve.get_baked_length()
	if total_length <= 0:
		return
	
	# Calculate duration based on speed
	var duration = total_length / max(patrol_speed, 1.0)
	
	# Kill existing tween
	if _tween and _tween.is_valid():
		if _tween.finished.is_connected(_on_path_complete):
			_tween.finished.disconnect(_on_path_complete)
		_tween.kill()
	
	# Switch to walk animation if available
	if has_walk_animation:
		_set_npc_animation("walk")
	
	_tween = create_tween()
	_tween.set_loops(1)
	
	# Animate progress along the path
	var remaining = 1.0 - _current_progress
	_tween.tween_method(_update_npc_position, _current_progress, 1.0, duration * remaining)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_LINEAR)
	
	_tween.finished.connect(_on_path_complete)

func _update_npc_position(progress: float):
	if not npc or not path:
		return
	_current_progress = progress
	var offset = path.curve.sample_baked(progress * path.curve.get_baked_length())
	npc.global_position = path.global_position + offset

func _on_path_complete():
	_current_progress = 0.0
	
	if _is_paused or not _is_patrolling:
		return
	
	# Pause at end before restarting
	await get_tree().create_timer(pause_time).timeout
	
	if _is_paused or not _is_patrolling:
		return
	_move_along_path()

func _pause_patrol():
	_is_paused = true
	if _tween and _tween.is_valid():
		if _tween.finished.is_connected(_on_path_complete):
			_tween.finished.disconnect(_on_path_complete)
		_tween.kill()
	
	# Switch back to idle animation
	if has_walk_animation:
		_set_npc_animation("idle")

func _resume_patrol():
	_is_paused = false
	# Resume from current position
	_move_along_path()

## Helper to set animation on the NPC's AnimatedSprite2D, if present.
func _set_npc_animation(anim_name: String):
	var anim_sprite = npc.get_node_or_null("AnimatedSprite2D")
	if anim_sprite and anim_sprite.has_method("play"):
		anim_sprite.play(anim_name)

## Public: Stop patrol completely (e.g., for a triggered event).
func stop_patrol():
	_is_patrolling = false
	_pause_patrol()

## Public: Restart patrol from beginning.
func restart_patrol():
	_current_progress = 0.0
	_start_patrol()
