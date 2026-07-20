## This script is attached to the Player node and is specifically designed to represent player entities in the game.
## The Player node serves as the foundation for creating main playable characters.
class_name PlayerEntity
extends CharacterEntity

@export_group("States")
@export var on_transfer_start: State ## State to enable when player starts transfering.
@export var on_transfer_end: State ## State to enable when player ends transfering.

var player_id: int = 1 ## A unique id that is assigned to the player on creation. Player 1 will have player_id = 1 and each additional player will have an incremental id, 2, 3, 4, and so on.
var equipped = 0 ## The id of the weapon equipped by the player.
var fireball_container: Node2D
var _footstep_rng := RandomNumberGenerator.new()
@export var fireball_projectile_scene: PackedScene = preload("res://fireball_node_adeeb/Projectiles/Projectile.tscn")

const GAME_OVER_SCENE: PackedScene = preload("res://scenes/menus/game_over.tscn")

func _ready():
	super._ready()
	_prepare_fireball_container()
	Globals.transfer_start.connect(func(): 
		on_transfer_start.enable()
	)
	Globals.transfer_complete.connect(func(): on_transfer_end.enable())
	Globals.destination_found.connect(func(destination_path): _move_to_destination(destination_path))
	receive_data(DataManager.get_player_data(player_id))

##Get the player data to save.
func get_data():
	var data = DataPlayer.new()
	var player_data = DataManager.get_player_data(player_id)
	if player_data:
		data = player_data
	data.position = position
	data.facing = facing
	data.hp = health_controller.hp
	data.max_hp = health_controller.max_hp
	if inventory:
		data.inventory = inventory.items
	else:
		data.inventory = []
	data.equipped = equipped
	return data

##Handle the received player data (from a save file or when moving to another level).
func receive_data(data):
	if data:
		global_position = data.position
		facing = data.facing
		health_controller.hp = data.hp
		health_controller.max_hp = data.max_hp
		if inventory:
			inventory.items = data.inventory
		equipped = data.equipped

func _move_to_destination(destination_path: String):
	if !destination_path:
		return
	var destination = get_tree().root.get_node(destination_path)
	if !destination:
		return
	var direction = facing
	if destination is Transfer and destination.direction:
		direction = destination.direction.to_vector
	DataManager.save_player_data(player_id, {
		position = destination.global_position,
		facing = direction
	})

func _prepare_fireball_container():
	fireball_container = get_node_or_null("FireballContainer")
	if not fireball_container:
		fireball_container = Node2D.new()
		fireball_container.name = "FireballContainer"
		add_child(fireball_container)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fireball"):
		print("[Player] Q pressed _input")
		cast_fireball()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fireball"):
		print("[Player] Q pressed _unhandled_input")
		cast_fireball()

func cast_fireball():
	if not fireball_projectile_scene:
		return
	_play_attack_animation()
	_prepare_fireball_container()
	var instance = fireball_projectile_scene.instantiate()
	if instance.has_method("set"):
		instance.set("player", self)
		var fire_direction = Vector2.DOWN
		if facing != Vector2.ZERO:
			fire_direction = facing
		instance.set("direction", fire_direction.normalized())
	fireball_container.add_child(instance)
	if instance.has_method("set_owner"):
		instance.set_owner(self)
	instance.global_position = global_position + instance.direction * 16
	print("[Fireball] spawned at", instance.global_position, "dir", instance.direction)

func _play_attack_animation() -> void:
	var animation = _get_attack_animation_name()
	var animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		print("[Player] AnimatedSprite2D node not found")
		return
	print("[Player] AnimatedSprite2D found", animated_sprite.name)
	if not animated_sprite.sprite_frames:
		print("[Player] AnimatedSprite2D has no sprite_frames")
		return
	var anim_names = animated_sprite.sprite_frames.get_animation_names()
	print("[Player] sprite animations available:", anim_names)
	print("[Player] requested animation:", animation)
	if animated_sprite.sprite_frames.has_animation(animation):
		animated_sprite.stop()
		animated_sprite.animation = animation
		animated_sprite.frame = 0
		animated_sprite.visible = true
		animated_sprite.play(animation)
		print("[Player] playing", animation)
		return
	print("[Player] no sprite animation found for", animation)
	var fallback = "attack-down"
	if animated_sprite.sprite_frames.has_animation(fallback):
		print("[Player] fallback to", fallback)
		animated_sprite.stop()
		animated_sprite.animation = fallback
		animated_sprite.frame = 0
		animated_sprite.visible = true
		animated_sprite.play(fallback)

func _get_attack_animation_name() -> String:
	var direction = Vector2.DOWN
	if facing != Vector2.ZERO:
		direction = facing
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			return "attack-right"
		return "attack-left"
	if direction.y > 0:
		return "attack-down"
	return "attack-up"

func _on_AnimatedSprite2D_frame_changed():
	var animated_sprite = $AnimatedSprite2D
	if not animated_sprite:
		return
	var anim_name = animated_sprite.animation
	if anim_name.begins_with("walk") or anim_name.begins_with("run"):
		var footstep = $SfxFootstep
		if footstep and not footstep.playing:
			footstep.volume_db = _footstep_rng.randf_range(-12.0, 0.0)
			footstep.pitch_scale = _footstep_rng.randf_range(0.8, 1.2)
			footstep.play()

func disable_entity(value: bool, delay = 0.0):
	await get_tree().create_timer(delay).timeout
	stop()
	input_enabled = !value

func _show_game_over():
	var game_over = GAME_OVER_SCENE.instantiate()
	get_tree().root.add_child(game_over)
