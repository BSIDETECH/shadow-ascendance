class_name Companion
extends CompanionBase

## Elemental Mage companion for "Shadow Cheat: Solo Guild Ascendance".
## Inherits CompanionBase and provides ranged elemental spellcasting:
## Fireball AoE explosions and Ice Spikes slowing projectiles.

@export_group("Mage Spellcasting")
@export var cast_cooldown: float = 1.2
@export var projectile_damage: float = 24.0
@export var projectiles_per_cast: int = 1
@export var ice_spike_chance: float = 0.35
@export var sensing_radius: float = 240.0
@export var ideal_follow_distance: float = 70.0
@export var follow_speed: float = 130.0
@export var leash_threshold: float = 180.0
@export var crowd_avoidance_distance: float = 40.0

var _cast_timer: float = 0.0

var fireball_scene: PackedScene = preload("res://scenes/entities/projectile/fireball.tscn")
var ice_spike_script: GDScript = preload("res://scripts/entities/ice_spike.gd")

func _init() -> void:
	max_health = 80.0
	current_health = 80.0
	move_speed = 135.0
	sprint_speed = 190.0
	companion_name = "Lyra"

func _ready() -> void:
	if enneagram_profile == null:
		enneagram_profile = EnneagramData.create_preset(EnneagramData.Type.REFORMER)
	super._ready()
	EventBus.spell_casted.connect(func():
		var player_node := get_tree().get_first_node_in_group("player")
		if has_meta("glyph_fury_unlocked") or (player_node != null and player_node.has_meta("glyph_fury_unlocked")):
			_cast_timer *= 0.5
	)
	if sprite != null and sprite.texture == null:
		sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0086.png")
		sprite.modulate = Color(0.8, 0.9, 1.2, 1.0)

func find_target_cluster() -> Node2D:
	return _select_combat_target(sensing_radius)

func get_target() -> Node2D:
	return _select_combat_target(sensing_radius)

func _handle_combat(delta: float) -> void:
	if current_tactical_state == TacticalOrderState.ORDER_RETREAT:
		var has_close_threat := _has_enemy_closer_than(50.0)
		if not has_close_threat:
			return

	var cd_mult := 1.25 if current_tactical_state == TacticalOrderState.ORDER_ATTACK else 1.0
	_cast_timer -= delta * cd_mult
	if _cast_timer <= 0.0:
		_cast_timer = cast_cooldown
		_cast_spell()

func _cast_spell() -> void:
	var target_node: Node2D = _select_combat_target(sensing_radius)
	if target_node == null:
		return

	EventBus.spell_casted.emit()

	var base_dir := (target_node.global_position - global_position).normalized()
	if base_dir == Vector2.ZERO:
		base_dir = Vector2.RIGHT

	var use_ice := randf() < ice_spike_chance

	if use_ice and ice_spike_script != null:
		var spike := ice_spike_script.new() as IceSpike
		if spike != null:
			spike.global_position = global_position
			spike.direction = base_dir
			spike.damage = projectile_damage * 0.75
			var parent := get_parent()
			if parent != null:
				parent.add_child(spike)
	elif fireball_scene != null:
		for i in range(projectiles_per_cast):
			var fb := fireball_scene.instantiate() as Fireball
			if fb != null:
				fb.global_position = global_position
				fb.damage = projectile_damage
				if projectiles_per_cast > 1:
					var angle_offset := (float(i) - float(projectiles_per_cast - 1) * 0.5) * 0.25
					fb.direction = base_dir.rotated(angle_offset)
				else:
					fb.direction = base_dir
				var parent := get_parent()
				if parent != null:
					parent.add_child(fb)

	if sprite != null:
		var tween := create_tween()
		if tween != null:
			tween.tween_property(sprite, "scale", Vector2(1.25, 1.25), 0.06)
			tween.tween_property(sprite, "scale", Vector2.ONE, 0.08)

func _has_enemy_closer_than(dist: float) -> bool:
	if not is_inside_tree():
		return false
	var world := get_world_2d()
	if world == null:
		return false
	var space_state := world.direct_space_state
	if space_state == null:
		return false

	var shape := CircleShape2D.new()
	shape.radius = dist

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results := space_state.intersect_shape(query, 32)
	for res in results:
		var col := res.collider as Node
		if col != null and col.is_in_group("enemies"):
			return true

	return false
