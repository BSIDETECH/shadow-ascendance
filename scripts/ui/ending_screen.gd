class_name EndingScreen
extends CanvasLayer

## Dual Ending Screen UI Component (M5)
## Displays narrative epilogue and telemetry metrics summary for
## "A Aliança dos Vivos" (Good Ending) vs "O Monstro Solitário" (Bad Ending).

signal return_to_hub_requested()

@onready var title_label: Label = find_child("TitleLabel", true, false) as Label
@onready var epilogue_label: Label = find_child("EpilogueLabel", true, false) as Label
@onready var surv_val_label: Label = find_child("SurvVal", true, false) as Label
@onready var rescue_val_label: Label = find_child("RescueVal", true, false) as Label
@onready var fallen_val_label: Label = find_child("FallenVal", true, false) as Label
@onready var reckless_val_label: Label = find_child("RecklessVal", true, false) as Label
@onready var score_val_label: Label = find_child("ScoreVal", true, false) as Label
@onready var return_button: Button = find_child("ReturnButton", true, false) as Button

var current_ending_type: String = "BAD_ENDING"
var current_metrics: Dictionary = {}

func _ready() -> void:
	layer = 110 # Above HUD and ordinary elements
	_ensure_references()
	if return_button != null and not return_button.pressed.is_connected(_on_return_button_pressed):
		return_button.pressed.connect(_on_return_button_pressed)

	# Fetch latest ending from GameManager or SilentAgencyTracker if not already populated
	var ending_type := ""
	var metrics: Dictionary = {}
	var tree := get_tree()
	if tree != null and tree.root != null:
		var gm = tree.root.get_node_or_null("GameManager")
		if gm != null:
			if gm.has_method("get_last_ending_type"):
				ending_type = gm.call("get_last_ending_type")
			if gm.has_method("get_last_ending_metrics"):
				metrics = gm.call("get_last_ending_metrics")
		if ending_type == "":
			var tracker = tree.root.get_node_or_null("SilentAgencyTracker")
			if tracker != null:
				if tracker.has_method("evaluate_ending"):
					ending_type = tracker.call("evaluate_ending")
				if tracker.has_method("get_metrics"):
					metrics = tracker.call("get_metrics")

	if ending_type != "":
		display_ending(ending_type, metrics)
	elif current_ending_type != "":
		display_ending(current_ending_type, current_metrics)

func _ensure_references() -> void:
	if title_label == null:
		title_label = find_child("TitleLabel", true, false) as Label
	if epilogue_label == null:
		epilogue_label = find_child("EpilogueLabel", true, false) as Label
	if surv_val_label == null:
		surv_val_label = find_child("SurvVal", true, false) as Label
	if rescue_val_label == null:
		rescue_val_label = find_child("RescueVal", true, false) as Label
	if fallen_val_label == null:
		fallen_val_label = find_child("FallenVal", true, false) as Label
	if reckless_val_label == null:
		reckless_val_label = find_child("RecklessVal", true, false) as Label
	if score_val_label == null:
		score_val_label = find_child("ScoreVal", true, false) as Label
	if return_button == null:
		return_button = find_child("ReturnButton", true, false) as Button

func display_ending(p_ending_type: String, p_metrics: Dictionary = {}) -> void:
	_ensure_references()
	current_ending_type = p_ending_type if p_ending_type != "" else "BAD_ENDING"
	current_metrics = p_metrics.duplicate()

	var is_good: bool = (current_ending_type == "GOOD_ENDING" or current_ending_type == "A Aliança dos Vivos")

	if title_label != null:
		if is_good:
			title_label.text = "A Aliança dos Vivos"
			title_label.set("theme_override_colors/font_color", Color(1.0, 0.85, 0.3, 1.0))
		else:
			title_label.text = "O Monstro Solitário"
			title_label.set("theme_override_colors/font_color", Color(0.9, 0.25, 0.25, 1.0))

	if epilogue_label != null:
		if is_good:
			epilogue_label.text = "Com discernimento, coragem e lealdade inabalável, você liderou seus companheiros através dos horrores das fortalezas ancestrais sem sucumbir à arrogância.\n\nA Aliança dos Vivos prevalece sobre o abismo, e a Taverna de Greyrock celebrará a união daqueles que lutaram lado a lado."
		else:
			epilogue_label.text = "Entre os escombros gélidos e as cinzas da batalha, apenas o eco de passos solitários permanece. Ordens insensatas e abandono transformaram a expedição em um massacre.\n\nVocê sobreviveu ao poder dos guardiões, mas na escuridão eterna, nada restou além de um monstro solitário."

	var survived: int = current_metrics.get("allies_survived", 0)
	var rescues: int = current_metrics.get("rescues_performed", 0)
	var fallen: int = current_metrics.get("allies_fallen", 0)
	var reckless: int = current_metrics.get("reckless_orders_issued", 0)
	var score: int = current_metrics.get("agency_score", 0)

	if surv_val_label != null:
		surv_val_label.text = "%d" % survived
	if rescue_val_label != null:
		rescue_val_label.text = "%d" % rescues
	if fallen_val_label != null:
		fallen_val_label.text = "%d" % fallen
	if reckless_val_label != null:
		reckless_val_label.text = "%d" % reckless
	if score_val_label != null:
		score_val_label.text = "%d" % score

func _on_return_button_pressed() -> void:
	return_to_hub_requested.emit()
	var tree := get_tree()
	if tree != null and tree.root != null:
		var gm = tree.root.get_node_or_null("GameManager")
		if gm != null and gm.has_method("transition_to_hub"):
			gm.call("transition_to_hub")
			return
		tree.change_scene_to_file("res://scenes/hub/greyrock_village.tscn")
