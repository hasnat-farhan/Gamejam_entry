extends CPUParticles2D

## Auto-deletes itself after the particle burst finishes.

func _ready() -> void:
	emitting = true
	# Wait for the particles to finish plus a small buffer
	await get_tree().create_timer(lifetime * 1.5).timeout
	queue_free()
