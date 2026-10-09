class_name BottomDialogueBox
extends CanvasLayer

## Caixa de diálogo estilo RPG clássico fixada no rodapé da tela.
## Suporta exibição com efeito máquina de escrever (typewriter), avanço ágil com E/clique,
## nome do NPC destacado e callbacks de conclusão.

signal dialogue_closed()
signal dialogue_advanced()

@onready var panel: PanelContainer = $PanelContainer
@onready var speaker_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DialogueLabel
@onready var action_hint: Label = $PanelContainer/MarginContainer/VBoxContainer/ActionHint

var _typewriter_tween: Tween = null
var _pulse_tween: Tween = null
var _is_typing: bool = false
var _full_text: String = ""
var _on_complete_callback: Callable = Callable()
var is_active: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_hint_pulse()

func show_dialogue(speaker: String, text: String, on_complete: Callable = Callable()) -> void:
	_full_text = text
	_on_complete_callback = on_complete
	is_active = true
	visible = true

	if speaker_label != null:
		speaker_label.text = speaker
		if speaker.is_empty():
			speaker_label.visible = false
		else:
			speaker_label.visible = true

	if dialogue_label != null:
		dialogue_label.text = text
		dialogue_label.visible_ratio = 0.0

	_start_typewriter(text)

func _start_typewriter(text: String) -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	_is_typing = true
	var char_count: int = text.length()
	var duration: float = clampf(char_count * 0.022, 0.4, 2.2)

	_typewriter_tween = create_tween().bind_node(self)
	_typewriter_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	_typewriter_tween.finished.connect(func():
		_is_typing = false
	)

func _skip_typewriter() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	if dialogue_label != null:
		dialogue_label.visible_ratio = 1.0
	_is_typing = false

func advance_dialogue() -> void:
	if not is_active or not visible:
		return

	if _is_typing:
		_skip_typewriter()
		dialogue_advanced.emit()
	else:
		close_dialogue()

func close_dialogue() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	_is_typing = false
	is_active = false
	visible = false

	if _on_complete_callback.is_valid():
		var cb := _on_complete_callback
		_on_complete_callback = Callable()
		cb.call()

	dialogue_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not is_active:
		return

	var is_adv := false
	if event.is_action_pressed("interact"):
		is_adv = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_adv = true
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		is_adv = true

	if is_adv:
		advance_dialogue()
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()

func _start_hint_pulse() -> void:
	if action_hint == null:
		return
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween().bind_node(self).set_loops()
	_pulse_tween.tween_property(action_hint, "modulate:a", 0.4, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(action_hint, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
