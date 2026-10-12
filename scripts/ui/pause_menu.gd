extends CanvasLayer

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()

func pause_game() -> void:
	get_tree().paused = true
	visible = true

func resume_game() -> void:
	get_tree().paused = false
	visible = false

func _on_resume_button_pressed() -> void:
	resume_game()

func _on_quit_button_pressed() -> void:
	resume_game()
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm != null and gm.has_method("transition_to_hub"):
		gm.transition_to_hub()
	else:
		get_tree().change_scene_to_file("res://scenes/hub/greyrock_village.tscn")
