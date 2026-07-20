extends Node2D
## Base script for interactive NPC characters.
## Handles the start_dialogue method called by the StateInteract -> StateCallable chain.

@export var dialogue_resource: DialogueResource
@export var dialogue_title: String = ""
@export var npc_name: String = ""

func _ready():
	if npc_name.is_empty():
		npc_name = name

## Called by StateCallable when the player interacts with this NPC.
## Shows the dialogue balloon with this NPC's dialogue.
func start_dialogue():
	if not dialogue_resource:
		push_warning("NPC %s has no dialogue resource assigned!" % name)
		return
	
	get_tree().paused = true
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_title)
	await DialogueManager.dialogue_ended
	get_tree().paused = false
