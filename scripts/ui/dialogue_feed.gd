class_name DialogueFeed
extends Control

const MAX_VISIBLE_MESSAGES := 4
const CARD_SCENE_PATH := "res://scenes/ui/dialogue_feed/dialogue_card.tscn"

@onready var cards_container: VBoxContainer = $FeedMargin/CardsContainer

var _card_scene: PackedScene
var _active_cards: Array[DialogueCard] = []

var _event_bus: Node = null

func _get_event_bus() -> Node:
	if _event_bus != null and is_instance_valid(_event_bus):
		return _event_bus
	var tree := get_tree()
	if tree != null:
		_event_bus = tree.root.get_node_or_null("EventBus")
	return _event_bus

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_scene = load(CARD_SCENE_PATH) if ResourceLoader.exists(CARD_SCENE_PATH) else null

	var eb := _get_event_bus()
	if eb != null and eb.has_signal("companion_dialogue_emitted"):
		if not eb.companion_dialogue_emitted.is_connected(_on_companion_dialogue_emitted):
			eb.companion_dialogue_emitted.connect(_on_companion_dialogue_emitted)

func post_message(
	speaker: String,
	text: String,
	status: int = DialogueCard.Status.INFO,
	portrait: Texture2D = null,
	override_color: Color = Color.WHITE
) -> void:
	# Enforce queue limit of 4 simultaneous messages
	while _active_cards.size() >= MAX_VISIBLE_MESSAGES:
		var oldest: DialogueCard = _active_cards.pop_front()
		if is_instance_valid(oldest):
			oldest.dismiss_now(true) # Fast dismiss on overflow

	var card: DialogueCard = null
	if _card_scene != null:
		card = _card_scene.instantiate() as DialogueCard
	else:
		card = _create_fallback_card()

	if card == null:
		return

	if cards_container != null:
		cards_container.add_child(card)
	else:
		add_child(card)

	_active_cards.append(card)
	card.card_expired.connect(_on_card_expired)
	card.setup_message(speaker, text, status, portrait, override_color)

func push_message(
	speaker: String,
	text: String,
	status: int = DialogueCard.Status.INFO,
	portrait: Texture2D = null,
	override_color: Color = Color.WHITE
) -> void:
	post_message(speaker, text, status, portrait, override_color)

func _on_companion_dialogue_emitted(speaker_name: String, text: String, color: Color) -> void:
	var status: int = DialogueCard.Status.INFO

	# Status deduction from color thresholds
	if color.g > 0.6 and color.r < 0.5:
		status = DialogueCard.Status.OBEY # Green
	elif color.r > 0.7 and color.g > 0.5 and color.b < 0.4:
		status = DialogueCard.Status.HESITATE # Yellow / Amber
	elif color.r > 0.7 and color.g < 0.5:
		status = DialogueCard.Status.REFUSE # Red
	else:
		status = DialogueCard.Status.INFO

	post_message(speaker_name, text, status, null, color)

func _on_card_expired(card_node: DialogueCard) -> void:
	_active_cards.erase(card_node)

func _create_fallback_card() -> DialogueCard:
	var card := DialogueCard.new()
	card.custom_minimum_size = Vector2(248, 34)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card

func clear_feed() -> void:
	for card in _active_cards:
		if is_instance_valid(card):
			card.queue_free()
	_active_cards.clear()
