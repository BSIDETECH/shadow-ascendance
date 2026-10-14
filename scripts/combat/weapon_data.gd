class_name WeaponData
extends Resource

## Data container for Player Weapons.
## Defines combat geometry, swing arc, damage type, cooldown, and visual FX.

@export var id: String = "dual_daggers"
@export var display_name: String = "Lâminas das Sombras"
@export var description: String = "Ataque veloz em arco crescente com dano sombrio contínuo."
@export var attack_cooldown: float = 0.28
@export var base_damage: float = 14.0
@export var damage_type: DamageData.DamageType = DamageData.DamageType.DARK
@export var hitbox_polygon: PackedVector2Array = PackedVector2Array([
	Vector2(0, -16), Vector2(28, -22), Vector2(44, 0), Vector2(28, 22), Vector2(0, 16), Vector2(20, 0)
])
@export var slash_color: Color = Color(1.2, 0.4, 1.8, 1.0)
@export var visual_scale_start: Vector2 = Vector2(0.6, 0.6)
@export var visual_scale_end: Vector2 = Vector2(1.2, 1.2)
@export var icon_tile: String = "tile_0087.png"

static func create_dual_daggers() -> WeaponData:
	var w := WeaponData.new()
	w.id = "dual_daggers"
	w.display_name = "Lâminas das Sombras"
	w.description = "Adagas ágeis em arco frontal rápido com DPS sombrio contínuo."
	w.attack_cooldown = 0.28
	w.base_damage = 14.0
	w.damage_type = DamageData.DamageType.DARK
	w.hitbox_polygon = PackedVector2Array([
		Vector2(0, -16), Vector2(28, -22), Vector2(44, 0), Vector2(28, 22), Vector2(0, 16), Vector2(20, 0)
	])
	w.slash_color = Color(1.2, 0.4, 1.8, 1.0)
	w.visual_scale_start = Vector2(0.6, 0.6)
	w.visual_scale_end = Vector2(1.2, 1.2)
	w.icon_tile = "tile_0087.png"
	return w

static func create_greatsword() -> WeaponData:
	var w := WeaponData.new()
	w.id = "greatsword"
	w.display_name = "Espadão do Carrasco"
	w.description = "Lâmina colossal com corte de 160°, alto alcance e tremendo impacto físico."
	w.attack_cooldown = 0.58
	w.base_damage = 34.0
	w.damage_type = DamageData.DamageType.PHYSICAL
	w.hitbox_polygon = PackedVector2Array([
		Vector2(0, -32), Vector2(35, -45), Vector2(65, 0), Vector2(35, 45), Vector2(0, 32), Vector2(24, 0)
	])
	w.slash_color = Color(1.8, 0.8, 0.3, 1.0)
	w.visual_scale_start = Vector2(0.8, 0.8)
	w.visual_scale_end = Vector2(1.4, 1.4)
	w.icon_tile = "tile_0088.png"
	return w

static func create_thunder_spear() -> WeaponData:
	var w := WeaponData.new()
	w.id = "thunder_spear"
	w.display_name = "Lança do Relâmpago"
	w.description = "Estocada penetrante de longo alcance que perfura fileiras de monstros."
	w.attack_cooldown = 0.38
	w.base_damage = 22.0
	w.damage_type = DamageData.DamageType.LIGHTNING
	w.hitbox_polygon = PackedVector2Array([
		Vector2(4, -8), Vector2(65, -10), Vector2(85, 0), Vector2(65, 10), Vector2(4, 8)
	])
	w.slash_color = Color(0.4, 1.2, 2.0, 1.0)
	w.visual_scale_start = Vector2(0.5, 0.5)
	w.visual_scale_end = Vector2(1.1, 1.1)
	w.icon_tile = "tile_0089.png"
	return w

static func create_reaper_scythe() -> WeaponData:
	var w := WeaponData.new()
	w.id = "reaper_scythe"
	w.display_name = "Foice do Ceifador"
	w.description = "Golpe circular em 360° que decepa todos os inimigos ao redor do jogador."
	w.attack_cooldown = 0.46
	w.base_damage = 18.0
	w.damage_type = DamageData.DamageType.DARK
	w.hitbox_polygon = PackedVector2Array([
		Vector2(0, -38), Vector2(28, -28), Vector2(40, 0), Vector2(28, 28),
		Vector2(0, 38), Vector2(-28, 28), Vector2(-40, 0), Vector2(-28, -28)
	])
	w.slash_color = Color(0.3, 1.8, 0.9, 1.0)
	w.visual_scale_start = Vector2(0.7, 0.7)
	w.visual_scale_end = Vector2(1.3, 1.3)
	w.icon_tile = "tile_0090.png"
	return w

static func get_all_weapons() -> Array[WeaponData]:
	return [
		create_dual_daggers(),
		create_greatsword(),
		create_thunder_spear(),
		create_reaper_scythe()
	]

static func get_random_weapon() -> WeaponData:
	var list := get_all_weapons()
	return list[randi() % list.size()]
