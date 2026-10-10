class_name RelicData
extends Resource

enum RelicType {
	STAT_MODIFIER,
	ON_KILL_HEAL,
	COOLDOWN_REDUCTION
}

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_path: String = "res://assets/kenney_tiny_dungeon/Tiles/tile_0115.png"
@export var relic_type: RelicType = RelicType.STAT_MODIFIER
@export var target: String = "player" # "player", "companion", "all"
@export var property_name: String = "" # e.g. "move_speed_mult", "max_health", "lifesteal_on_kill"
@export var value: float = 0.0

func _init(_id: String = "", _display_name: String = "", _desc: String = "", _type: RelicType = RelicType.STAT_MODIFIER, _target: String = "player", _prop: String = "", _val: float = 0.0, _icon: String = "res://assets/kenney_tiny_dungeon/Tiles/tile_0115.png") -> void:
	id = _id
	display_name = _display_name
	description = _desc
	relic_type = _type
	target = _target
	property_name = _prop
	value = _val
	icon_path = _icon
