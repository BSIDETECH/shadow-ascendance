class_name DestructibleUrn
extends StaticBody2D

## Destructible urn / ancient crate / tombstone relic in the forest.
## Drops gold, XP gems, and rewards player exploration.

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var health_component: HealthComponent = $HealthComponent

@export var gold_reward: int = 5
@export var is_tombstone: bool = false

var xp_gem_scene: PackedScene = preload("res://scenes/entities/xp_gem/xp_gem.tscn")
var _is_destroyed: bool = false

func _ready() -> void:
	add_to_group("destructible")
	if health_component:
		health_component.max_health = 15.0
		health_component.current_health = 15.0
		health_component.died.connect(_on_died)
	if hurtbox:
		hurtbox.team_index = 2 # Neutral/Environment team
		hurtbox.collision_layer = 2 | 4 | 64
		hurtbox.collision_mask = 0

func _on_died() -> void:
	if _is_destroyed:
		return
	_is_destroyed = true

	var tree := get_tree()
	if tree != null and tree.root != null:
		var gm = tree.root.get_node_or_null("GameManager")
		if gm != null and gm.has_method("add_gold"):
			gm.call("add_gold", gold_reward)

		var am = tree.root.get_node_or_null("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.call("play_sfx", "spell", 0.2, -1.0)

	if xp_gem_scene != null and get_parent() != null:
		var gem = xp_gem_scene.instantiate() as XPGem
		if gem != null:
			gem.xp_value = 2
			gem.global_position = global_position
			get_parent().call_deferred("add_child", gem)

	set_physics_process(false)
	var tween := create_tween()
	if tween != null:
		tween.tween_property(sprite, "scale", Vector2(1.3, 0.3), 0.12)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.12)
		tween.tween_callback(queue_free)
	else:
		queue_free()
