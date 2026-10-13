extends CanvasLayer

## Pause & In-Game Audio Settings Menu
## Accessible anytime via ESC or GUI button.

@onready var master_slider: HSlider = %MasterSlider
@onready var master_label: Label = %MasterValueLabel
@onready var bgm_slider: HSlider = %BGMSlider
@onready var bgm_label: Label = %BGMValueLabel
@onready var sfx_slider: HSlider = %SFXSlider
@onready var sfx_label: Label = %SFXValueLabel
@onready var ui_slider: HSlider = %UISlider
@onready var ui_label: Label = %UIValueLabel

var _updating_sliders: bool = false

func _ready() -> void:
	visible = false
	_connect_signals()

func _connect_signals() -> void:
	if master_slider:
		master_slider.value_changed.connect(_on_master_slider_changed)
	if bgm_slider:
		bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)
		sfx_slider.drag_ended.connect(_on_sfx_drag_ended)
	if ui_slider:
		ui_slider.value_changed.connect(_on_ui_slider_changed)
		ui_slider.drag_ended.connect(_on_ui_drag_ended)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()

func pause_game() -> void:
	get_tree().paused = true
	sync_sliders_from_audio_manager()
	visible = true

func resume_game() -> void:
	get_tree().paused = false
	visible = false
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr != null and audio_mgr.has_method("save_audio_settings"):
		audio_mgr.save_audio_settings()

func sync_sliders_from_audio_manager() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr == null:
		return
	
	_updating_sliders = true
	
	var m_vol: float = audio_mgr.get_bus_volume(&"Master") * 100.0
	var b_vol: float = audio_mgr.get_bus_volume(&"BGM") * 100.0
	var s_vol: float = audio_mgr.get_bus_volume(&"SFX") * 100.0
	var u_vol: float = audio_mgr.get_bus_volume(&"UI") * 100.0

	if master_slider:
		master_slider.value = m_vol
		if master_label:
			master_label.text = "%d%%" % int(round(m_vol))
	if bgm_slider:
		bgm_slider.value = b_vol
		if bgm_label:
			bgm_label.text = "%d%%" % int(round(b_vol))
	if sfx_slider:
		sfx_slider.value = s_vol
		if sfx_label:
			sfx_label.text = "%d%%" % int(round(s_vol))
	if ui_slider:
		ui_slider.value = u_vol
		if ui_label:
			ui_label.text = "%d%%" % int(round(u_vol))

	_updating_sliders = false

func _on_master_slider_changed(value: float) -> void:
	if _updating_sliders:
		return
	if master_label:
		master_label.text = "%d%%" % int(value)
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr != null:
		audio_mgr.set_bus_volume(&"Master", value / 100.0)

func _on_bgm_slider_changed(value: float) -> void:
	if _updating_sliders:
		return
	if bgm_label:
		bgm_label.text = "%d%%" % int(value)
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr != null:
		audio_mgr.set_bus_volume(&"BGM", value / 100.0)

func _on_sfx_slider_changed(value: float) -> void:
	if _updating_sliders:
		return
	if sfx_label:
		sfx_label.text = "%d%%" % int(value)
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr != null:
		audio_mgr.set_bus_volume(&"SFX", value / 100.0)

func _on_sfx_drag_ended(_value_changed: bool) -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr != null:
		audio_mgr.play_sfx("hit", 0.0, 0.0)
		audio_mgr.save_audio_settings()

func _on_ui_slider_changed(value: float) -> void:
	if _updating_sliders:
		return
	if ui_label:
		ui_label.text = "%d%%" % int(value)
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr != null:
		audio_mgr.set_bus_volume(&"UI", value / 100.0)

func _on_ui_drag_ended(_value_changed: bool) -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr != null:
		audio_mgr.play_ui("click", 0.0)
		audio_mgr.save_audio_settings()

func _on_resume_button_pressed() -> void:
	resume_game()

func _on_quit_button_pressed() -> void:
	resume_game()
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm != null and gm.has_method("transition_to_hub"):
		gm.transition_to_hub()
	else:
		get_tree().change_scene_to_file("res://scenes/hub/greyrock_village.tscn")
