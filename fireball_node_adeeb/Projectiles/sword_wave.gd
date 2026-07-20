extends Area2D

## Power sword attack projectile — a wave of energy that travels forward.
## Higher damage than normal attacks, slower to execute, disappears on hit.

@export var speed: float = 250.0
@export var direction: Vector2 = Vector2.DOWN
@export var damage: int = 3
@export var player: Node

@onready var sprite: Sprite2D = $Sprite2D

signal enemy_hit

## Hit effect scene spawned on contact.
var explosion_scene: PackedScene = preload("res://fireball_node_adeeb/fireball_explosion.tscn")

## Custom-generated crescent slash texture (static = generated once for all instances).
static var slash_texture: Texture2D = null

func _init():
	# Detect enemy bodies on collision layer 1 (entity root layer)
	collision_mask = 2

func _ready():
	if not player:
		var ancestor = get_parent()
		while ancestor and not (ancestor is PlayerEntity):
			ancestor = ancestor.get_parent()
		if ancestor and ancestor is PlayerEntity:
			player = ancestor
	if not player:
		push_error("SwordWave has no player reference")
		queue_free()
		return
	
	if direction == Vector2.ZERO:
		direction = player.facing if player.facing != Vector2.ZERO else Vector2.DOWN
	direction = direction.normalized()
	
	# Generate custom slash texture if not already done
	if not slash_texture:
		slash_texture = _generate_slash_texture()
	sprite.texture = slash_texture
	
	# Rotate the sprite to face the direction
	sprite.rotation = direction.angle()
	
	body_entered.connect(_on_body_entered)
	set_physics_process(true)
	print("[SwordWave] spawned at", global_position, "dir", direction)

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		_apply_damage(body)

func _apply_damage(target: Node) -> void:
	# Spawn hit effect at impact point
	_spawn_hit_effect()
	
	var health_controller = target.get_node_or_null("HealthController") as HealthController
	if health_controller:
		health_controller.change_hp(-damage, name)
		emit_signal("enemy_hit")
		queue_free()
		return
	
	# Fallback for old-style enemies
	if target.get("health") != null:
		target.health -= damage
		emit_signal("enemy_hit")
		queue_free()

func _spawn_hit_effect() -> void:
	var explosion = explosion_scene.instantiate()
	var root = get_tree().current_scene
	if root:
		root.add_child(explosion)
	else:
		get_parent().add_child(explosion)
	explosion.global_position = global_position

func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()

## Generates a custom crescent/slash arc texture for the sword wave.
func _generate_slash_texture() -> Texture2D:
	var width = 64
	var height = 32
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var cx = width / 2.0
	var cy = height / 2.0
	
	for x in range(width):
		for y in range(height):
			# Map to -1..1 range
			var nx = (x - cx) / (width / 2.0)
			var ny = (y - cy) / (height / 2.0)
			var dist = sqrt(nx * nx + ny * ny)
			var angle = atan2(ny, nx)
			
			# Outer arc: a thick curved line angled slightly
			# The arc goes from about -60 to 60 degrees
			var in_angle_range = abs(angle) < 1.2
			var in_radius_range = dist > 0.4 and dist < 0.85
			
			if in_angle_range and in_radius_range:
				# Edge glow: fade at the edges
				var edge_factor = 1.0
				var dist_from_center = abs(dist - 0.625)
				if dist_from_center > 0.15:
					edge_factor = max(0, 1.0 - (dist_from_center - 0.15) * 5.0)
				
				# Angle fade: dimmer at the tips
				var angle_factor = max(0, 1.0 - abs(angle) * 0.6)
				
				var alpha = edge_factor * angle_factor * 0.85
				if alpha > 0.05:
					# Cyan-white core with blue edges
					var r = 0.6 + 0.4 * angle_factor
					var g = 0.8 + 0.2 * angle_factor
					var b = 1.0
					img.set_pixel(x, y, Color(r, g, b, alpha))
	
	return ImageTexture.create_from_image(img)
