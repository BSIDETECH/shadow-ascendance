class_name WeaponChest
extends Area2D

## Interactive Weapon Chest that rolls and equips a random WeaponData for the player.
## Positioned in the arena to replace hardcoded level-1 weapon unlocks.

signal weapon_granted(weapon: WeaponData)

@export var is_opened: bool = false
@export var predetermined_weapon: WeaponData = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel

var _player_in_range: Player = null

func _ready() -> void:
	add_to_group("interactive")
	add_to_group("chests")
	collision_layer = 0
	collision_mask = 2 # Player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if prompt_label != null:
		prompt_label.visible = false
		prompt_label.text = "[E] Abrir Baú de Armas"

func _unhandled_input(event: InputEvent) -> void:
	if is_opened or _player_in_range == null:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		open_chest()

func _on_body_entered(body: Node2D) -> void:
	if is_opened:
		return
	if body is Player or body.is_in_group("player"):
		_player_in_range = body as Player
		if prompt_label != null:
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if prompt_label != null:
			prompt_label.visible = false

func open_chest(target_player: Player = null) -> WeaponData:
	if is_opened:
		return null
	is_opened = true
	if prompt_label != null:
		prompt_label.visible = false

	# Roll weapon
	var weapon: WeaponData = predetermined_weapon
	if weapon == null:
		weapon = WeaponData.get_random_weapon()

	# Equip to player
	var player_to_equip: Player = target_player if target_player != null else _player_in_range
	if player_to_equip == null and is_inside_tree():
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Player:
			player_to_equip = players[0] as Player

	if player_to_equip != null and is_instance_valid(player_to_equip):
		player_to_equip.equip_weapon(weapon)

	weapon_granted.emit(weapon)

	# Sound effect
	if is_inside_tree() and get_tree().root != null:
		var am = get_tree().root.get_node_or_null("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.call("play_sfx", "confirm", 0.0, 2.0)

	# HUD Announcement
	if Engine.has_singleton("EventBus") or (is_inside_tree() and get_tree().root.has_node("EventBus")):
		EventBus.emit_arena_announcement("✦ ARMA OBTIDA: %s! ✦" % weapon.display_name.to_upper(), false)

	# Visual transition: open chest
	if sprite != null:
		var opened_texture := load("res://assets/kenney_tiny_dungeon/Tiles/tile_0090.png") as Texture2D
		if opened_texture != null:
			sprite.texture = opened_texture
		if is_inside_tree():
			var tween := create_tween()
			if tween != null:
				tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.12)
				tween.parallel().tween_property(sprite, "modulate", Color(2.0, 1.8, 0.8), 0.12)
				tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.15)
				tween.parallel().tween_property(sprite, "modulate", Color(1.0, 0.95, 0.8), 0.15)

	return weapon
