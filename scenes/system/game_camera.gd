## Handle main camera movement and target following.  
class_name GameCamera
extends Camera2D

@export var target_manager: TargetManager

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0

func _process(_delta: float) -> void:
	_follow_target()

##internal - Manages camera tracking of the assigned target.
func _follow_target():
	if target_manager and target_manager.target:
		global_position = target_manager.get_target_position()
