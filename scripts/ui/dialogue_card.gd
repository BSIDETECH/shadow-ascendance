class_name DialogueCard
extends PanelContainer

signal card_expired(card_node: DialogueCard)

enum Status {
	OBEY = 0,
	HESITATE = 1,
	REFUSE = 2,
	INFO = 3
}

const STYLE_PRESETS := {
	Status.OBEY: {
		"border_color": Color(0.22, 0.88, 0.42, 1.0),
		"bg_color": Color(0.04, 0.14, 0.07, 0.90),
		"tag_text": "[OBEDECE]",
		"tag_color": Color(0.35, 1.0, 0.55, 1.0)
	},
	Status.HESITATE: {
		"border_color": Color(1.0, 0.78, 0.18, 1.0),
		"bg_color": Color(0.16, 0.12, 0.03, 0.90),
		"tag_text": "[HESITA]",
		"tag_color": Color(1.0, 0.88, 0.35, 1.0)
	},
	Status.REFUSE: {
		"border_color": Color(1.0, 0.25, 0.30, 1.0),
		"bg_color": Color(0.18, 0.04, 0.06, 0.90),
		"tag_text": "[RECUSA]",
		"tag_color": Color(1.0, 0.45, 0.50, 1.0)
	},
	Status.INFO: {
		"border_color": Color(0.35, 0.70, 1.0, 1.0),
		"bg_color": Color(0.05, 0.08, 0.16, 0.90),
		"tag_text": "[RÁDIO]",
		"tag_color": Color(0.60, 0.85, 1.0, 1.0)
	}
}

const PORTRAIT_FALLBACKS := {
	"lyra": "res://assets/kenney_tiny_dungeon/Tiles/tile_0087.png",
	"maga": "res://assets/kenney_tiny_dungeon/Tiles/tile_0087.png",
	"wizard": "res://assets/kenney_tiny_dungeon/Tiles/tile_0087.png",
	"paladino": "res://assets/kenney_tiny_dungeon/Tiles/tile_0085.png",
	"paladin": "res://assets/kenney_tiny_dungeon/Tiles/tile_0085.png",
	"arqueira": "res://assets/kenney_tiny_dungeon/Tiles/tile_0086.png",
	"archer": "res://assets/kenney_tiny_dungeon/Tiles/tile_0086.png",
	"elena": "res://assets/kenney_tiny_dungeon/Tiles/tile_0090.png",
	"barnaby": "res://assets/kenney_tiny_dungeon/Tiles/tile_0089.png",
	"selene": "res://assets/kenney_tiny_dungeon/Tiles/tile_0088.png"
}

@onready var portrait_rect: TextureRect = $Margin/HBox/Portrait
@onready var speaker_label: Label = $Margin/HBox/ContentVBox/HeaderHBox/SpeakerLabel
@onready var status_badge: Label = $Margin/HBox/ContentVBox/HeaderHBox/StatusBadge
@onready var message_label: Label = $Margin/HBox/ContentVBox/MessageLabel

var _lifetime_tween: Tween
var _is_dismissing: bool = false

func setup_message(
	speaker: String,
	text: String,
	status: int = Status.INFO,
	portrait: Texture2D = null,
	override_color: Color = Color.WHITE
) -> void:
	if speaker_label != null:
		speaker_label.text = speaker
	if message_label != null:
		message_label.text = text

	# Resolve status preset
	var st: int = clampi(status, 0, Status.INFO)
	var preset: Dictionary = STYLE_PRESETS.get(st, STYLE_PRESETS[Status.INFO])

	# Visual Box Styling
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = preset["bg_color"]
	style_box.border_color = override_color if override_color != Color.WHITE else preset["border_color"]
	style_box.border_width_left = 3
	style_box.border_width_top = 1
	style_box.border_width_right = 1
	style_box.border_width_bottom = 1
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_right = 4
	style_box.corner_radius_bottom_left = 4
	add_theme_stylebox_override("panel", style_box)

	# Status Badge
	if status_badge != null:
		status_badge.text = preset["tag_text"]
		status_badge.add_theme_color_override("font_color", preset["tag_color"])

	# Portrait resolution
	if portrait_rect != null:
		if portrait != null:
			portrait_rect.texture = portrait
		else:
			_assign_fallback_portrait(speaker)

	_start_fade_in_and_timer()

func _assign_fallback_portrait(speaker: String) -> void:
	if portrait_rect == null:
		return
	var lower_name := speaker.to_lower()
	var path := ""
	for key: String in PORTRAIT_FALLBACKS.keys():
		if lower_name.contains(key):
			path = PORTRAIT_FALLBACKS[key]
			break
	if path == "":
		path = "res://assets/kenney_tiny_dungeon/Tiles/tile_0084.png" # default icon

	if ResourceLoader.exists(path):
		portrait_rect.texture = load(path)

func _start_fade_in_and_timer() -> void:
	modulate.a = 0.0
	if _lifetime_tween != null and _lifetime_tween.is_valid():
		_lifetime_tween.kill()

	_lifetime_tween = create_tween()
	if _lifetime_tween != null:
		_lifetime_tween.bind_node(self)
		_lifetime_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_lifetime_tween.tween_property(self, "modulate:a", 1.0, 0.22)
		_lifetime_tween.tween_interval(3.5) # Auto-dismiss after 3.5 seconds
		_lifetime_tween.tween_property(self, "modulate:a", 0.0, 0.32).set_ease(Tween.EASE_IN)
		_lifetime_tween.tween_callback(_on_dismiss_complete)

func dismiss_now(fast: bool = false) -> void:
	if _is_dismissing:
		return
	_is_dismissing = true

	if _lifetime_tween != null and _lifetime_tween.is_valid():
		_lifetime_tween.kill()

	var duration := 0.12 if fast else 0.25
	var tw := create_tween()
	if tw != null:
		tw.bind_node(self)
		tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(self, "modulate:a", 0.0, duration)
		tw.tween_callback(_on_dismiss_complete)
	else:
		_on_dismiss_complete()

func _on_dismiss_complete() -> void:
	card_expired.emit(self)
	queue_free()
