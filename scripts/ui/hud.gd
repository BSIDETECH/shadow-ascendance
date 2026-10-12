class_name GameHUD
extends CanvasLayer

@onready var hp_bar: ProgressBar = $Control/Margin/VBox/HPContainer/HPBar
@onready var hp_label: Label = $Control/Margin/VBox/HPContainer/HPLabel
@onready var mana_bar: ProgressBar = $Control/Margin/VBox/ManaContainer/ManaBar
@onready var mana_label: Label = $Control/Margin/VBox/ManaContainer/ManaLabel
@onready var xp_bar: ProgressBar = $Control/Margin/VBox/XPContainer/XPBar
@onready var xp_label: Label = $Control/Margin/VBox/XPContainer/XPLabel
@onready var kills_label: Label = $Control/Margin/VBox/KillsLabel
@onready var time_label: Label = $Control/Margin/VBox/TimeLabel

# Leadership UI elements
@onready var leadership_container: VBoxContainer = $Control/Margin/VBox/LeadershipContainer
@onready var charges_count_label: Label = $Control/Margin/VBox/LeadershipContainer/HeaderHBox/ChargesCountLabel
@onready var pips_hbox: HBoxContainer = $Control/Margin/VBox/LeadershipContainer/PipsHBox
@onready var pip1: Panel = $Control/Margin/VBox/LeadershipContainer/PipsHBox/Pip1
@onready var pip2: Panel = $Control/Margin/VBox/LeadershipContainer/PipsHBox/Pip2
@onready var pip3: Panel = $Control/Margin/VBox/LeadershipContainer/PipsHBox/Pip3
@onready var recharge_label: Label = $Control/Margin/VBox/LeadershipContainer/RechargeLabel
@onready var dialogue_feed: DialogueFeed = $Control/DialogueFeed

var _pips: Array[Panel] = []
var _style_active: StyleBox
var _style_empty: StyleBox
var _survival_seconds: float = 0.0
var _shake_tween: Tween
var _last_charges: int = 3

var _event_bus: Node = null

func _get_event_bus() -> Node:
	if _event_bus != null and is_instance_valid(_event_bus):
		return _event_bus
	var tree := get_tree()
	if tree != null:
		_event_bus = tree.root.get_node_or_null("EventBus")
	return _event_bus

func _ready() -> void:
	if pip1 != null and pip2 != null and pip3 != null:
		_pips = [pip1, pip2, pip3]
		_style_active = pip1.get_theme_stylebox("panel")
		_create_fallback_empty_style()

	var eb := _get_event_bus()
	if eb != null:
		if eb.has_signal("player_health_changed"):
			eb.player_health_changed.connect(update_health)

		if eb.has_signal("player_mana_changed"):
			eb.player_mana_changed.connect(update_mana)

		if eb.has_signal("leadership_charges_changed"):
			eb.leadership_charges_changed.connect(update_leadership_charges)

		if eb.has_signal("leadership_order_failed"):
			eb.leadership_order_failed.connect(_on_leadership_order_failed)

		if eb.has_signal("gold_changed"):
			eb.gold_changed.connect(_on_gold_changed)

	_setup_gold_hud()
	update_leadership_charges(3, 3)

func _setup_gold_hud() -> void:
	if kills_label != null and kills_label.get_parent() != null:
		var parent = kills_label.get_parent()
		var gold_label = Label.new()
		gold_label.name = "GoldLabel"
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		gold_label.add_theme_font_size_override("font_size", 12)
		var gm = get_tree().root.get_node_or_null("GameManager")
		gold_label.text = "💰 Ouro: " + str(gm.get_gold() if gm != null and gm.has_method("get_gold") else 0)
		parent.add_child(gold_label)

func _on_gold_changed(new_gold: int) -> void:
	if kills_label != null and kills_label.get_parent() != null:
		var gold_label = kills_label.get_parent().get_node_or_null("GoldLabel")
		if gold_label != null:
			gold_label.text = "💰 Ouro: " + str(new_gold)

func _create_fallback_empty_style() -> void:
	var empty := StyleBoxFlat.new()
	empty.bg_color = Color(0.12, 0.12, 0.16, 0.75)
	empty.border_width_left = 1
	empty.border_width_top = 1
	empty.border_width_right = 1
	empty.border_width_bottom = 1
	empty.border_color = Color(0.32, 0.32, 0.38, 0.6)
	empty.corner_radius_top_left = 3
	empty.corner_radius_top_right = 3
	empty.corner_radius_bottom_right = 3
	empty.corner_radius_bottom_left = 3
	_style_empty = empty

func _process(delta: float) -> void:
	_survival_seconds += delta
	var minutes := int(_survival_seconds) / 60
	var seconds := int(_survival_seconds) % 60
	if time_label != null:
		time_label.text = "Tempo: %02d:%02d" % [minutes, seconds]

func update_health(current: float, max_hp: float) -> void:
	if hp_bar != null:
		hp_bar.max_value = max_hp
		hp_bar.value = current
	if hp_label != null:
		hp_label.text = "HP: %d/%d" % [int(current), int(max_hp)]

func update_mana(current: float, max_mana: float) -> void:
	if mana_bar != null:
		mana_bar.max_value = max_mana
		mana_bar.value = current
	if mana_label != null:
		mana_label.text = "Mana: %d/%d" % [int(current), int(max_mana)]

func update_xp(current_xp: int, next_xp: int, level: int) -> void:
	if xp_bar != null:
		xp_bar.max_value = next_xp
		xp_bar.value = current_xp
	if xp_label != null:
		xp_label.text = "Nv. %d (XP: %d/%d)" % [level, current_xp, next_xp]

func update_kills(kills: int) -> void:
	if kills_label != null:
		kills_label.text = "Abates: %d" % kills
	if recharge_label != null:
		var prog: int = kills % 10
		recharge_label.text = "Recarga: %d/10 abates" % prog

func update_leadership_charges(current: int, max_charges: int = 3) -> void:
	if charges_count_label != null:
		charges_count_label.text = "[ %d/%d ]" % [current, max_charges]

	for i in range(_pips.size()):
		var pip := _pips[i]
		if pip != null:
			if i < current:
				if _style_active != null:
					pip.add_theme_stylebox_override("panel", _style_active)
				if current > _last_charges and i == current - 1:
					play_charge_gained_punch(i)
			else:
				if _style_empty != null:
					pip.add_theme_stylebox_override("panel", _style_empty)

	_last_charges = current

func _on_leadership_order_failed(_reason: String) -> void:
	play_leadership_error_shake()

func play_leadership_error_shake() -> void:
	if pips_hbox == null:
		return
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()

	_shake_tween = create_tween()
	if _shake_tween != null:
		var orig_x: float = pips_hbox.position.x
		_shake_tween.set_trans(Tween.TRANS_SINE)
		_shake_tween.tween_property(pips_hbox, "position:x", orig_x - 4.0, 0.04)
		_shake_tween.tween_property(pips_hbox, "position:x", orig_x + 4.0, 0.04)
		_shake_tween.tween_property(pips_hbox, "position:x", orig_x - 2.0, 0.04)
		_shake_tween.tween_property(pips_hbox, "position:x", orig_x + 2.0, 0.04)
		_shake_tween.tween_property(pips_hbox, "position:x", orig_x, 0.04)

func play_charge_gained_punch(pip_index: int) -> void:
	if pip_index >= 0 and pip_index < _pips.size():
		var pip := _pips[pip_index]
		if pip != null:
			var tw := create_tween()
			if tw != null:
				tw.bind_node(pip)
				tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(pip, "scale", Vector2(1.25, 1.25), 0.10)
				tw.tween_property(pip, "scale", Vector2.ONE, 0.12)
