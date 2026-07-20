extends CPUParticles2D

## Auto-deletes itself after the dust puff finishes.

func _ready() -> void:
	emitting = true
	await get_tree().create_timer(lifetime * 1.5).timeout
	queue_free()
