extends Node

## AudioManager AutoLoad
## Centralized audio pooling, sound limiter, crossfade music and bus routing.
## Follows godot-audio-systems best practices.

const BUS_MASTER: StringName = &"Master"
const BUS_BGM: StringName = &"BGM"
const BUS_SFX: StringName = &"SFX"
const BUS_UI: StringName = &"UI"

const SFX_POOL_SIZE: int = 24
const MAX_CONCURRENT_SAME_SFX: int = 3
const SFX_COOLDOWN_WINDOW_SEC: float = 0.06

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_usage_timestamps: Dictionary = {} # String -> Array[float]

var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer
var _current_music_key: String = ""

# Preloaded sound registry
var _sound_registry: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_init_sfx_pool()
	_init_music_players()
	_load_sound_registry()
	_connect_event_bus()
	_setup_scene_music_monitor()
	_setup_auto_button_hook()
	load_audio_settings()

func _ensure_buses() -> void:
	var required_buses: Array[StringName] = [BUS_BGM, BUS_SFX, BUS_UI]
	for bus_name in required_buses:
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx == -1:
			var new_idx: int = AudioServer.bus_count
			AudioServer.add_bus(new_idx)
			AudioServer.set_bus_name(new_idx, bus_name)
			AudioServer.set_bus_send(new_idx, BUS_MASTER)

func _init_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		player.name = "SFXPlayer_%d" % i
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_sfx_pool.append(player)

func _init_music_players() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.name = "MusicPlayer_A"
	_music_player_a.bus = BUS_BGM
	_music_player_a.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player_a)

	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.name = "MusicPlayer_B"
	_music_player_b.bus = BUS_BGM
	_music_player_b.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player_b)

	_active_music_player = _music_player_a

func _load_sound_registry() -> void:
	# SFX
	_register_sound("slash", "res://assets/audio/rpg/knifeSlice.ogg")
	_register_sound("attack", "res://assets/audio/rpg/chop.ogg")
	_register_sound("hit", "res://assets/audio/impact/impactPunch_medium_001.ogg")
	_register_sound("impact", "res://assets/audio/impact/impactMetal_heavy_001.ogg")
	_register_sound("dash", "res://assets/audio/rpg/clothBelt.ogg")
	_register_sound("death", "res://assets/audio/rpg/dropLeather.ogg")
	_register_sound("spell", "res://assets/audio/rpg/metalPot1.ogg")
	_register_sound("xp_gem", "res://assets/audio/rpg/handleCoins2.ogg")
	_register_sound("gold", "res://assets/audio/rpg/handleCoins.ogg")
	_register_sound("level_up", "res://assets/audio/music/jingles_HIT15.ogg")
	_register_sound("wave_start", "res://assets/audio/music/jingles_HIT07.ogg")
	_register_sound("wave_clear", "res://assets/audio/music/jingles_HIT10.ogg")
	_register_sound("order", "res://assets/audio/rpg/drawKnife1.ogg")
	_register_sound("order_failed", "res://assets/audio/interface/error_001.ogg")
	
	# UI
	_register_sound("click", "res://assets/audio/interface/click_001.ogg")
	_register_sound("confirm", "res://assets/audio/interface/confirmation_001.ogg")
	_register_sound("back", "res://assets/audio/interface/back_001.ogg")
	_register_sound("close", "res://assets/audio/interface/close_001.ogg")
	_register_sound("book", "res://assets/audio/rpg/bookOpen.ogg")
	_register_sound("door", "res://assets/audio/rpg/doorOpen_1.ogg")

	# BGM
	_register_sound("bgm_hub", "res://assets/audio/music/jingles_PIZZI07.ogg")
	_register_sound("bgm_arena", "res://assets/audio/music/jingles_NES00.ogg")
	_register_sound("bgm_dungeon", "res://assets/audio/music/jingles_NES15.ogg")
	_register_sound("bgm_victory", "res://assets/audio/music/jingles_HIT14.ogg")

func _register_sound(key: String, file_path: String) -> void:
	var stream: AudioStream = _load_audio_stream(file_path)
	if stream != null:
		_sound_registry[key] = stream

func _load_audio_stream(file_path: String) -> AudioStream:
	if ResourceLoader.exists(file_path):
		var res = load(file_path)
		if res is AudioStream:
			return res
	if FileAccess.file_exists(file_path):
		if file_path.ends_with(".ogg"):
			return AudioStreamOggVorbis.load_from_file(file_path)
	return null

func _connect_event_bus() -> void:
	if not Engine.has_singleton("EventBus") and not get_node_or_null("/root/EventBus"):
		return
	
	var eb = get_node("/root/EventBus")
	if eb.has_signal("player_dashed"):
		eb.player_dashed.connect(func(_dir): play_sfx("dash", 0.08, -2.0))
	if eb.has_signal("damage_dealt"):
		eb.damage_dealt.connect(func(_target, _data): play_sfx("hit", 0.12, -1.0))
	if eb.has_signal("xp_collected"):
		eb.xp_collected.connect(func(_amount): play_sfx("xp_gem", 0.06, -4.0))
	if eb.has_signal("level_up_requested"):
		eb.level_up_requested.connect(func(_lvl): play_sfx("level_up", 0.0, 1.0))
	if eb.has_signal("enemy_died"):
		eb.enemy_died.connect(func(_pos, _xp): play_sfx("death", 0.1, -2.0))
	if eb.has_signal("wave_started"):
		eb.wave_started.connect(func(_w): play_sfx("wave_start", 0.0, 0.0))
	if eb.has_signal("wave_completed"):
		eb.wave_completed.connect(func(_w): play_sfx("wave_clear", 0.0, 0.0))
	if eb.has_signal("leadership_order_issued"):
		eb.leadership_order_issued.connect(func(_type, _pos): play_sfx("order", 0.05, 0.0))
	if eb.has_signal("leadership_order_failed"):
		eb.leadership_order_failed.connect(func(_reason): play_sfx("order_failed", 0.0, 0.0))
	if eb.has_signal("spell_casted"):
		eb.spell_casted.connect(func(): play_sfx("spell", 0.08, -1.0))
	if eb.has_signal("gacha_card_selected"):
		eb.gacha_card_selected.connect(func(_c): play_ui("confirm"))

## Plays a sound effect using voice pooling and duplicate limiting
func play_sfx(sound_name_or_stream: Variant, pitch_variation: float = 0.05, volume_db: float = 0.0) -> AudioStreamPlayer:
	var stream: AudioStream = _resolve_stream(sound_name_or_stream)
	if stream == null:
		return null
	
	var sound_key := str(sound_name_or_stream)
	if not _passes_limiter(sound_key):
		return null
	
	var player := _get_free_sfx_player()
	if player == null:
		return null
	
	player.bus = BUS_SFX
	player.stream = stream
	player.volume_db = volume_db
	if pitch_variation > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	else:
		player.pitch_scale = 1.0
	
	player.play()
	return player

## Plays a UI sound on the UI bus
func play_ui(sound_name_or_stream: Variant, volume_db: float = 0.0) -> AudioStreamPlayer:
	var stream: AudioStream = _resolve_stream(sound_name_or_stream)
	if stream == null:
		return null
	
	var player := _get_free_sfx_player()
	if player == null:
		return null
	
	player.bus = BUS_UI
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0
	player.play()
	return player

## Crossfades into new background music
func play_music(music_name_or_stream: Variant, crossfade_duration: float = 1.0, loop: bool = true) -> void:
	var stream: AudioStream = _resolve_stream(music_name_or_stream)
	if stream == null:
		return
	
	var key := str(music_name_or_stream)
	if key == _current_music_key and _active_music_player.playing:
		return # Already playing this track
	
	_current_music_key = key
	
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	
	var outgoing_player := _active_music_player
	var incoming_player := _music_player_b if _active_music_player == _music_player_a else _music_player_a
	_active_music_player = incoming_player
	
	incoming_player.stream = stream
	incoming_player.volume_db = -40.0
	incoming_player.play()
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(incoming_player, "volume_db", -4.0, crossfade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if outgoing_player.playing:
		tween.tween_property(outgoing_player, "volume_db", -40.0, crossfade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(outgoing_player.stop)

## Stops background music with a fade out
func stop_music(fade_duration: float = 1.0) -> void:
	_current_music_key = ""
	if _active_music_player and _active_music_player.playing:
		var tween := create_tween()
		tween.tween_property(_active_music_player, "volume_db", -40.0, fade_duration)
		tween.tween_callback(_active_music_player.stop)

## Voice limiter to prevent audio spam
func _passes_limiter(key: String) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if not _sfx_usage_timestamps.has(key):
		_sfx_usage_timestamps[key] = [now]
		return true
	
	var timestamps: Array = _sfx_usage_timestamps[key]
	var recent: Array = []
	for t in timestamps:
		if now - t < SFX_COOLDOWN_WINDOW_SEC:
			recent.append(t)
	
	if recent.size() >= MAX_CONCURRENT_SAME_SFX:
		return false
	
	recent.append(now)
	_sfx_usage_timestamps[key] = recent
	return true

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	# If all busy, steal the player closest to ending or the first one
	return _sfx_pool[0]

func _resolve_stream(source: Variant) -> AudioStream:
	if source is AudioStream:
		return source
	if source is String:
		if _sound_registry.has(source):
			return _sound_registry[source]
		return _load_audio_stream(source)
	return null

const CONFIG_PATH: String = "user://audio_settings.cfg"

## Volume management using linear (0.0 to 1.0) <-> dB mapping
func set_bus_volume(bus_name: StringName, linear_val: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		if linear_val <= 0.001:
			AudioServer.set_bus_mute(idx, true)
		else:
			AudioServer.set_bus_mute(idx, false)
			AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear_val, 0.0001, 1.0)))

func get_bus_volume(bus_name: StringName) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		if AudioServer.is_bus_mute(idx):
			return 0.0
		return db_to_linear(AudioServer.get_bus_volume_db(idx))
	return 1.0

func set_bus_muted(bus_name: StringName, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_mute(idx, muted)

func is_bus_muted(bus_name: StringName) -> bool:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		return AudioServer.is_bus_mute(idx)
	return false

func save_audio_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", get_bus_volume(BUS_MASTER))
	cfg.set_value("audio", "bgm", get_bus_volume(BUS_BGM))
	cfg.set_value("audio", "sfx", get_bus_volume(BUS_SFX))
	cfg.set_value("audio", "ui", get_bus_volume(BUS_UI))
	cfg.save(CONFIG_PATH)

func load_audio_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err == OK:
		set_bus_volume(BUS_MASTER, float(cfg.get_value("audio", "master", 1.0)))
		set_bus_volume(BUS_BGM, float(cfg.get_value("audio", "bgm", 0.8)))
		set_bus_volume(BUS_SFX, float(cfg.get_value("audio", "sfx", 1.0)))
		set_bus_volume(BUS_UI, float(cfg.get_value("audio", "ui", 1.0)))

## Hooks any button to play a UI click sound automatically
func hook_button(btn: BaseButton) -> void:
	if btn != null and not btn.pressed.is_connected(_on_button_pressed):
		btn.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	play_ui("click", -2.0)

## Recursively hooks all BaseButtons inside a control or scene
func hook_ui(root: Node) -> void:
	if root is BaseButton:
		hook_button(root)
	for child in root.get_children():
		hook_ui(child)

func _setup_auto_button_hook() -> void:
	get_tree().node_added.connect(_on_node_added_to_tree)

func _on_node_added_to_tree(node: Node) -> void:
	if node is BaseButton:
		hook_button(node)

## Automatically detects current scene changes and changes BGM
func _setup_scene_music_monitor() -> void:
	get_tree().root.child_entered_tree.connect(_on_tree_child_entered)
	call_deferred("_check_current_scene_music")

func _on_tree_child_entered(node: Node) -> void:
	if node == get_tree().current_scene:
		call_deferred("_check_current_scene_music")

func _check_current_scene_music() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	
	var scene_name := scene.name.to_lower()
	var scene_path := scene.scene_file_path.to_lower()
	
	if "village" in scene_name or "hub" in scene_path or "village" in scene_path:
		play_music("bgm_hub", 1.5)
	elif "arena" in scene_name or "arena" in scene_path:
		play_music("bgm_arena", 1.0)
	elif "dungeon" in scene_name or "fortress" in scene_path or "ruined" in scene_name:
		play_music("bgm_dungeon", 1.2)
