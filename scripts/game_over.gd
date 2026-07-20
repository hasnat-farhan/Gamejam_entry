extends CanvasLayer

## Game Over screen that slides in from the top with a faded black background.
## Provides "Try Again" (reloads current scene) and "Quit" (returns to start screen) buttons.

@onready var background: ColorRect = $Background
@onready var panel: VBoxContainer = $Panel
@onready var try_again_btn: Button = $Panel/TryAgainButton
@onready var quit_btn: Button = $Panel/QuitButton

func _ready() -> void:
	# Start hidden
	background.modulate.a = 0.0
	panel.position.y = -400
	
	try_again_btn.pressed.connect(_on_try_again_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	# Pause the game tree so nothing moves in the background
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Wait a frame for layout to resolve sizes
	await get_tree().process_frame
	
	# Play the entrance animation
	_animate_in()

func _animate_in() -> void:
	# Fade in the dark background
	var bg_tween := create_tween()
	bg_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	bg_tween.tween_property(background, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	
	# Slide the panel down from above after a small delay
	var panel_tween := create_tween()
	panel_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	panel_tween.tween_interval(0.3)
	panel_tween.tween_property(panel, "position:y", panel.get_viewport_rect().size.y / 2.0 - panel.size.y / 2.0, 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Give focus to Try Again after animation completes
	panel_tween.tween_callback(try_again_btn.grab_focus)

func _on_try_again_pressed() -> void:
	get_tree().paused = false
	var current_level = Globals.get_current_level()
	if current_level:
		var path = current_level.scene_file_path
		SceneManager.swap_scenes(path, get_tree().root, current_level)
	else:
		get_tree().reload_current_scene()
	queue_free()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	var current_level = Globals.get_current_level()
	SceneManager.swap_scenes("res://scenes/menus/start_screen.tscn", get_tree().root, current_level)
	queue_free()

