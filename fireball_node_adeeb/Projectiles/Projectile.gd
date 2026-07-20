extends Area2D

@export var ProjType: Resource
@export var speed: float = 400.0
@export var direction: Vector2 = Vector2.RIGHT
@export var ProjDamage: int = 0
@export var ProjKnockback: int = 0
@export var player: Node

@onready var sprite = $Sprite2D
@onready var fireball_texture: Texture2D = preload("res://fireball_node_adeeb/Fireball.png")
var animation_player: AnimationPlayer
var anim_time: float = 0.0
var base_sprite_scale: Vector2 = Vector2.ONE

signal enemy_attacked

func change_proj():
	if not ProjType:
		ProjType = load("res://fireball_node_adeeb/Projectiles/Fireball.tres")

func _ready():
	if not player:
		var ancestor = get_parent()
		while ancestor and not (ancestor is PlayerEntity):
			ancestor = ancestor.get_parent()
		if ancestor and ancestor is PlayerEntity:
			player = ancestor
	if not player:
		push_error("Projectile has no player reference")
		queue_free()
		return
	var firing_direction = Vector2.DOWN
	if player.facing != Vector2.ZERO:
		firing_direction = player.facing
	elif player.knockback_dir != Vector2.ZERO:
		firing_direction = player.knockback_dir
	if get_parent() != player:
		global_position = player.global_position
	if direction == Vector2.ZERO:
		direction = firing_direction.normalized()
	change_proj()
	animation_player = get_node_or_null("AnimationPlayer")
	if animation_player:
		if animation_player.has_animation("fireball"):
			animation_player.play("fireball")
		elif animation_player.has_animation("fire"):
			animation_player.play("fire")
	if not ProjType:
		push_error("Projectile has no ProjType")
		queue_free()
		return
	if ProjType.image:
		sprite.texture = ProjType.image
	else:
		sprite.texture = fireball_texture
	if not sprite.texture:
		sprite.texture = fireball_texture
	if firing_direction.x != 0:
		sprite.rotation = 0
		sprite.flip_h = firing_direction.x < 0
	if firing_direction.y == 1:
		sprite.rotation = 90
	if firing_direction.y == -1:
		sprite.rotation = -90
	if firing_direction.y != 0:
		sprite.scale.y = abs(sprite.scale.y) * sign(firing_direction.y)

	speed = ProjType.Speed
	ProjKnockback = ProjType.Knockback
	ProjDamage = ProjType.Damage
	base_sprite_scale = sprite.scale
	set_physics_process(true)
	print("[Projectile] ready", global_position, "dir", direction, "player", player.name)

func _physics_process(delta):
	global_position += direction * speed * delta
	anim_time += delta
	# simple pulsing animation for the fireball
	var pulse = 1.0 + sin(anim_time * 12.0) * 0.08
	sprite.scale = base_sprite_scale * pulse

func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()


func _on_area_entered(area):
	if area.is_in_group("Enemy"):
		area.get_parent().knockback = player.knockback_dir * ProjKnockback
		area.get_parent().health -= ProjDamage
		emit_signal("enemy_attacked")
