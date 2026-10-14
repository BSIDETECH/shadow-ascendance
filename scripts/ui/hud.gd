class_name GameHUD
extends CanvasLayer

@onready var hp_container: HBoxContainer = $Control/Margin/VBox/HPContainer
@onready var hp_bar: ProgressBar = find_child("HPBar", true, false) as ProgressBar
@onready var shield_bar: ProgressBar = find_child("ShieldBar", true, false) as ProgressBar
@onready var hp_label: Label = find_child("HPLabel", true, false) as Label
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

		if eb.has_signal("player_shield_changed"):
			eb.player_shield_changed.connect(update_shield)

		if eb.has_signal("leadership_charges_changed"):
			eb.leadership_charges_changed.connect(update_leadership_charges)

		if eb.has_signal("leadership_order_failed"):
			eb.leadership_order_failed.connect(_on_leadership_order_failed)

		if eb.has_signal("gold_changed"):
			eb.gold_changed.connect(_on_gold_changed)

		if eb.has_signal("arena_announcement"):
			eb.arena_announcement.connect(show_announcement)

	_setup_gold_hud()
	_setup_potions_hud()
	_setup_announcement_banner()
	_setup_party_hud()
	update_leadership_charges(3, 3)

	var settings_btn := get_node_or_null("Control/Margin/TopRight/SettingsButton") as Button
	if settings_btn != null:
		settings_btn.pressed.connect(func():
			var pm = get_tree().root.get_node_or_null("PauseMenu")
			if pm != null and pm.has_method("pause_game"):
				pm.pause_game()
		)

var health_potions_label: Label = null
var shield_potions_label: Label = null
var revive_potions_label: Label = null
var barrier_potions_label: Label = null
var shield_label: Label = null

func _setup_potions_hud() -> void:
	if hp_container == null:
		return

	health_potions_label = Label.new()
	health_potions_label.add_theme_font_size_override("font_size", 10)
	health_potions_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	shield_potions_label = Label.new()
	shield_potions_label.add_theme_font_size_override("font_size", 10)
	shield_potions_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))

	revive_potions_label = Label.new()
	revive_potions_label.add_theme_font_size_override("font_size", 10)
	revive_potions_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))

	barrier_potions_label = Label.new()
	barrier_potions_label.add_theme_font_size_override("font_size", 10)
	barrier_potions_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))

	shield_label = Label.new()
	shield_label.add_theme_font_size_override("font_size", 12)
	shield_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	shield_label.text = ""

	var vbox = VBoxContainer.new()
	vbox.add_child(health_potions_label)
	vbox.add_child(shield_potions_label)
	vbox.add_child(revive_potions_label)
	vbox.add_child(barrier_potions_label)
	hp_container.get_parent().add_child(vbox)
	hp_container.get_parent().add_child(shield_label)

	_on_potions_changed(GameManager.health_potions, GameManager.shield_potions, GameManager.revive_potions, GameManager.barrier_potions)

	var eb = _get_event_bus()
	if eb and eb.has_signal("player_shield_changed"):
		eb.player_shield_changed.connect(_on_shield_changed)

	if GameManager.has_signal("potions_changed"):
		GameManager.potions_changed.connect(_on_potions_changed)

func _on_potions_changed(health_count: int, shield_count: int, revive_count: int = 0, barrier_count: int = 0) -> void:
	if health_potions_label:
		health_potions_label.text = "[4/F] Poções de Vida: " + str(health_count)
	if shield_potions_label:
		shield_potions_label.text = "[5/G] Poções de Escudo: " + str(shield_count)
	if revive_potions_label:
		revive_potions_label.text = "[6/R] Poções de Ressurreição: " + str(revive_count)
	if barrier_potions_label:
		barrier_potions_label.text = "[7/T] Poções de Barreira: " + str(barrier_count)

func _on_shield_changed(current: float, _max_shield: float) -> void:
	if shield_label:
		if current > 0.0:
			shield_label.text = "🛡️ Escudo: " + str(int(current))
		else:
			shield_label.text = ""

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

var party_vbox: VBoxContainer = null
var _companion_ui_entries: Array[Dictionary] = []

func _setup_party_hud() -> void:
	if party_vbox != null:
		return
	var vbox_parent = get_node_or_null("Control/Margin/VBox")
	if vbox_parent == null:
		return

	party_vbox = VBoxContainer.new()
	party_vbox.name = "PartyStatusContainer"
	party_vbox.add_theme_constant_override("separation", 3)
	vbox_parent.add_child(party_vbox)

func _update_party_hud() -> void:
	if not is_inside_tree():
		return
	if party_vbox == null:
		_setup_party_hud()
	if party_vbox == null:
		return

	var tree := get_tree()
	if tree == null:
		return
	var companions := tree.get_nodes_in_group("companions")
	if companions.is_empty():
		party_vbox.visible = false
		return

	party_vbox.visible = true

	var needs_rebuild := false
	if _companion_ui_entries.size() != companions.size():
		needs_rebuild = true
	else:
		for i in range(companions.size()):
			if _companion_ui_entries[i].node != companions[i]:
				needs_rebuild = true
				break

	if needs_rebuild:
		_rebuild_party_hud(companions)

	for entry in _companion_ui_entries:
		var comp: Node = entry.node
		if not is_instance_valid(comp):
			continue
		var hc: HealthComponent = comp.get_node_or_null("HealthComponent") as HealthComponent
		if hc == null:
			continue

		var cur_hp: float = hc.current_health
		var max_hp: float = maxf(1.0, hc.max_health)
		entry.bar.max_value = max_hp
		entry.bar.value = cur_hp

		if comp.get("is_dying") or (hc.current_health <= 0.0 and not hc.get("is_downed")):
			entry.status.text = "💀 BAIXA"
			entry.status.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			entry.bar.modulate = Color(0.4, 0.4, 0.4, 0.8)
		elif hc.get("is_downed"):
			entry.status.text = "⚠️ CAÍDO!"
			entry.status.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			entry.bar.modulate = Color(1.0, 0.2, 0.2, 1.0)
		else:
			entry.status.text = "%d/%d" % [int(cur_hp), int(max_hp)]
			entry.status.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
			var ratio: float = cur_hp / max_hp
			if ratio > 0.5:
				entry.bar.modulate = Color(0.3, 0.9, 0.4, 1.0)
			elif ratio > 0.25:
				entry.bar.modulate = Color(1.0, 0.8, 0.2, 1.0)
			else:
				entry.bar.modulate = Color(1.0, 0.3, 0.2, 1.0)

func _rebuild_party_hud(companions: Array) -> void:
	for child in party_vbox.get_children():
		child.queue_free()
	_companion_ui_entries.clear()

	var title := Label.new()
	title.text = "GRUPO DE ALIADOS"
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0, 0.95))
	party_vbox.add_child(title)

	for comp in companions:
		if not is_instance_valid(comp):
			continue
		var comp_name: String = str(comp.get("companion_name")) if comp.get("companion_name") != null else "Aliado"
		var icon_prefix := "🛡️ " if comp is CompanionPaladin or comp.name.contains("Paladin") else ("🏹 " if comp is CompanionArcher or comp.name.contains("Archer") else ("🔥 " if comp is CompanionMage or comp.name.contains("Mage") else "🗡️ "))

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)

		var name_lbl := Label.new()
		name_lbl.text = icon_prefix + comp_name
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98))
		name_lbl.custom_minimum_size = Vector2(72, 0)
		row.add_child(name_lbl)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(75, 7)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = Color(0.15, 0.15, 0.18, 0.8)
		bg_style.corner_radius_top_left = 2
		bg_style.corner_radius_top_right = 2
		bg_style.corner_radius_bottom_right = 2
		bg_style.corner_radius_bottom_left = 2
		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = Color.WHITE
		fill_style.corner_radius_top_left = 2
		fill_style.corner_radius_top_right = 2
		fill_style.corner_radius_bottom_right = 2
		fill_style.corner_radius_bottom_left = 2
		bar.add_theme_stylebox_override("background", bg_style)
		bar.add_theme_stylebox_override("fill", fill_style)
		row.add_child(bar)

		var status_lbl := Label.new()
		status_lbl.text = "100%"
		status_lbl.add_theme_font_size_override("font_size", 8)
		status_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		row.add_child(status_lbl)

		party_vbox.add_child(row)

		_companion_ui_entries.append({
			"node": comp,
			"bar": bar,
			"status": status_lbl
		})

func _process(delta: float) -> void:
	_survival_seconds += delta
	var minutes := int(_survival_seconds / 60.0)
	var seconds := int(_survival_seconds) % 60
	if time_label != null:
		time_label.text = "Tempo: %02d:%02d" % [minutes, seconds]
	_update_party_hud()

func update_health(current: float, max_hp: float) -> void:
	if hp_bar != null:
		hp_bar.max_value = max_hp
		hp_bar.value = current
	if hp_label != null:
		hp_label.text = "HP: %d/%d" % [int(current), int(max_hp)]

func update_shield(current: float, max_val: float) -> void:
	if shield_bar != null:
		shield_bar.max_value = max_val
		shield_bar.value = current
		shield_bar.visible = current > 0

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

var announcement_banner: Label = null

func _setup_announcement_banner() -> void:
	if announcement_banner == null:
		announcement_banner = Label.new()
		announcement_banner.name = "ArenaAnnouncementBanner"
		announcement_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		announcement_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		announcement_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
		announcement_banner.offset_top = 22.0
		announcement_banner.offset_bottom = 44.0
		announcement_banner.add_theme_font_size_override("font_size", 11)
		announcement_banner.add_theme_color_override("font_outline_color", Color.BLACK)
		announcement_banner.add_theme_constant_override("outline_size", 3)
		announcement_banner.modulate.a = 0.0
		var ctrl = get_node_or_null("Control")
		if ctrl != null:
			ctrl.add_child(announcement_banner)

func show_announcement(msg: String, is_danger: bool = false, duration: float = 3.2) -> void:
	_setup_announcement_banner()
	if announcement_banner == null:
		return
	announcement_banner.text = msg
	if is_danger:
		announcement_banner.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	else:
		announcement_banner.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))

	var tween := create_tween()
	announcement_banner.modulate.a = 0.0
	tween.tween_property(announcement_banner, "modulate:a", 1.0, 0.25)
	tween.tween_interval(duration)
	tween.tween_property(announcement_banner, "modulate:a", 0.0, 0.35)
