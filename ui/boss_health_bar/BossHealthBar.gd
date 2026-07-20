extends CanvasLayer
class_name BossHealthBar

## Boss health bar overlay with fade-in/out animations.
## Finds a boss node in the scene group "Boss" and listens to its health changes.
## Uses call_deferred to ensure the boss has registered itself in the group before searching.

@onready var boss_name_label: RichTextLabel = $BossName
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hide_timer: Timer = $HideTimer

var _boss_node: Node = null
var _health_controller: HealthController = null

func _ready() -> void:
	# Defer boss search to ensure all nodes have called _ready() and registered in groups
	call_deferred("_find_and_connect_boss")

## Finds the first node in the "Boss" group and connects to its health controller.
func _find_and_connect_boss() -> void:
	# Try to find boss by group
	var bosses = get_tree().get_nodes_in_group("Boss")
	if bosses.is_empty():
		# Fallback: recursively search scene tree for a node with boss signals/methods
		var candidates = _find_boss_nodes(get_tree().current_scene)
		if not candidates.is_empty():
			bosses = candidates
	
	if bosses.is_empty():
		push_warning("BossHealthBar: No boss node found in the scene. Add a boss to group 'Boss'.")
		return
	
	_boss_node = bosses[0]
	if not _boss_node:
		return
	
	# Connect to the boss's health controller
	if _boss_node.has_node("HealthController"):
		_health_controller = _boss_node.get_node("HealthController") as HealthController
		health_bar.max_value = _health_controller.max_hp
		health_bar.value = _health_controller.hp
		_health_controller.hp_changed.connect(_on_boss_hp_changed)
	
	# Set boss name if available
	if _boss_node.has_method("get_boss_name"):
		boss_name_label.text = _boss_node.get_boss_name()
	elif _boss_node.has_meta("boss_name"):
		boss_name_label.text = _boss_node.get_meta("boss_name")
	else:
		boss_name_label.text = _boss_node.name
	
	# Only show the bar after successfully finding and connecting to a boss
	show_health_bar()

## Recursively search for a node that looks like a boss (has boss methods/signals).
func _find_boss_nodes(node: Node) -> Array:
	var results: Array = []
	if node.has_method("get_boss_name") or node.has_signal("boss_health_changed"):
		results.append(node)
	
	for child in node.get_children():
		var child_results = _find_boss_nodes(child)
		results.append_array(child_results)
	
	return results

func _on_boss_hp_changed(hp: int) -> void:
	health_bar.value = hp
	if hp <= 0:
		hide_health_bar()

func show_health_bar() -> void:
	if animation_player.has_animation("fade_in"):
		animation_player.play("fade_in")

func hide_health_bar() -> void:
	if animation_player.has_animation("fade_out"):
		animation_player.play("fade_out")
		hide_timer.start()

func _on_hide_timer_timeout() -> void:
	queue_free()
