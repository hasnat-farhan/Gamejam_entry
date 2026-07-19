@icon("res://icons/Transfer.svg")
extends Node2D
##Transfers an entity to a different level or position.
class_name Transfer

@export_file("*.tscn") var level_path = "" ## Leave empty to transfer inside the same level.
@export var destination_name: String = "" ## The name of the destnation. NOTE: destination must be in the "destination" group.
@export_category("Destination settings")
## Force the player to face this direction upon arriving to this destination. [br]
## Leave empty to keep the same facing direction.
@export var direction: Direction

## Tracks the Transfer that initiated the current level transfer so only it emits the global signals.
static var _active_transfer: Transfer = null

func _ready() -> void:
	SceneManager.load_start.connect(_on_scene_load_start)
	SceneManager.scene_added.connect(_on_scene_added)

func _on_scene_load_start(_loading_screen) -> void:
	# Only the Transfer that initiated the level swap should emit transfer_start.
	if _active_transfer == self:
		Globals.transfer_start.emit()

func _on_scene_added(incoming_scene, _loading_screen) -> void:
	if _active_transfer == self:
		_complete_transfer(incoming_scene)
		_active_transfer = null

func _complete_transfer(incoming_scene):
	_check_transfer(incoming_scene)
	Globals.transfer_complete.emit()

func transfer(params):
	if params == null or not params.has("entity"):
		push_warning("Transfer received invalid params.")
		return
	var entity: CharacterEntity = params["entity"]
	if entity is PlayerEntity and not level_path.is_empty():
		_transfer_to_level(entity, level_path)
	elif is_instance_valid(entity) and not destination_name.is_empty():
		_transfer_to_position(entity)

func _transfer_to_level(player, scene_to_load):
	var current_level: Level = Globals.get_current_level()
	if current_level and is_instance_valid(player):
		current_level.receive_data({
			destination_name = destination_name,
			player_id = player.player_id
		})
		DataManager.save_level_data()
		_active_transfer = self
		SceneManager.swap_scenes(
			scene_to_load,
			current_level.get_parent(),
			current_level,
			Const.TRANSITION.FADE_TO_BLACK
		)
	else:
		push_warning("Transfer could not proceed because the current level or player was invalid.")

func _transfer_to_position(entity):
	Globals.transfer_start.emit()
	var destination = Globals.get_destination(destination_name)
	if destination:
		entity.global_position = destination.global_position
		if destination is Transfer and destination.direction:
			entity.facing = destination.direction.to_vector
	else:
		push_warning("%s: destination %s not found!" % [get_path(), destination])
	await get_tree().create_timer(0.5).timeout
	Globals.transfer_complete.emit()

func _check_transfer(incoming_scene):
	if incoming_scene is not Level:
		return
	var current_level: Level = incoming_scene
	if !current_level:
		return
	var level_data = current_level.get_data()
	if level_data and level_data.destination_name == name:
		Globals.destination_found.emit(get_path())
