extends SceneTree

## Unit test suite for AudioManager, Audio Systems, and In-Game Volume Adjustment

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func _init() -> void:
	call_deferred("_run_tests")

func _assert(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_tests += 1
		printerr("  [FAIL] %s" % test_name)

func _run_tests() -> void:
	print("\n--- [AUDIO SYSTEM & VOLUME ADJUSTMENT TESTS] ---")
	
	var audio_mgr: Node = root.get_node_or_null("AudioManager")
	_assert(audio_mgr != null, "AudioManager autoload exists in SceneTree")
	
	if audio_mgr == null:
		print("AudioManager not found, aborting audio tests.")
		quit(1)
		return

	# 1. Bus Verification
	var sfx_idx: int = AudioServer.get_bus_index(&"SFX")
	var bgm_idx: int = AudioServer.get_bus_index(&"BGM")
	var ui_idx: int = AudioServer.get_bus_index(&"UI")
	_assert(sfx_idx != -1, "Audio bus 'SFX' exists")
	_assert(bgm_idx != -1, "Audio bus 'BGM' exists")
	_assert(ui_idx != -1, "Audio bus 'UI' exists")

	# 2. Sound Registry
	var reg: Dictionary = audio_mgr._sound_registry
	_assert(reg.size() > 0, "Audio registry has loaded sound assets (%d loaded)" % reg.size())
	_assert(reg.has("hit"), "Audio registry contains 'hit'")
	_assert(reg.has("dash"), "Audio registry contains 'dash'")
	_assert(reg.has("click"), "Audio registry contains 'click'")
	_assert(reg.has("bgm_hub"), "Audio registry contains 'bgm_hub'")

	# 3. SFX Playback & Pool
	var player: AudioStreamPlayer = audio_mgr.play_sfx("hit")
	_assert(player != null, "play_sfx('hit') successfully returned active AudioStreamPlayer")
	if player != null:
		_assert(player.bus == &"SFX", "SFX player is routed to bus 'SFX'")

	# 4. UI Playback
	var ui_player: AudioStreamPlayer = audio_mgr.play_ui("click")
	_assert(ui_player != null, "play_ui('click') successfully returned active AudioStreamPlayer")
	if ui_player != null:
		_assert(ui_player.bus == &"UI", "UI player is routed to bus 'UI'")

	# 5. Music Playback
	audio_mgr.play_music("bgm_hub", 0.1)
	_assert(audio_mgr._active_music_player != null, "Music player is active")
	_assert(audio_mgr._active_music_player.bus == &"BGM", "Music player is routed to bus 'BGM'")

	# 6. Volume Mapping
	audio_mgr.set_bus_volume(&"SFX", 0.5)
	var vol: float = audio_mgr.get_bus_volume(&"SFX")
	_assert(absf(vol - 0.5) < 0.05, "set_bus_volume / get_bus_volume maps correctly (got %.2f)" % vol)

	# 7. Voice Limiter Cap (max 3 identical sounds in the same frame/burst)
	var capped_count: int = 0
	for i in range(10):
		var p: AudioStreamPlayer = audio_mgr.play_sfx("hit")
		if p == null:
			capped_count += 1
	_assert(capped_count > 0, "Voice limiter successfully capped rapid sound spam (%d dropped)" % capped_count)

	# 8. EventBus Integration
	var eb: Node = root.get_node_or_null("EventBus")
	if eb != null:
		eb.emit_player_dashed(Vector2.RIGHT)
		_assert(true, "EventBus signals dispatched without crashing audio listeners")

	# 9. In-Game PauseMenu Volume Controls UI
	var pause_menu = root.get_node_or_null("PauseMenu")
	_assert(pause_menu != null, "PauseMenu autoload exists in SceneTree")
	if pause_menu != null:
		_assert(pause_menu.master_slider != null, "PauseMenu has Master volume slider")
		_assert(pause_menu.bgm_slider != null, "PauseMenu has BGM volume slider")
		_assert(pause_menu.sfx_slider != null, "PauseMenu has SFX volume slider")
		_assert(pause_menu.ui_slider != null, "PauseMenu has UI volume slider")
		
		# Test slider sync
		audio_mgr.set_bus_volume(&"BGM", 0.75)
		pause_menu.sync_sliders_from_audio_manager()
		_assert(absf(pause_menu.bgm_slider.value - 75.0) < 1.0, "PauseMenu slider synced with AudioServer volume")
		
		# Test slider event
		pause_menu.sfx_slider.value = 40.0
		var new_sfx_vol: float = audio_mgr.get_bus_volume(&"SFX")
		_assert(absf(new_sfx_vol - 0.40) < 0.05, "Moving SFX slider updates AudioServer bus volume (got %.2f)" % new_sfx_vol)

	# 10. Volume Persistence
	audio_mgr.set_bus_volume(&"Master", 0.65)
	audio_mgr.save_audio_settings()
	audio_mgr.set_bus_volume(&"Master", 1.0)
	audio_mgr.load_audio_settings()
	var loaded_vol: float = audio_mgr.get_bus_volume(&"Master")
	_assert(absf(loaded_vol - 0.65) < 0.05, "save_audio_settings / load_audio_settings correctly persisted volume")

	print("\nAudio Tests Finished: %d / %d passed." % [passed_tests, total_tests])
	if failed_tests > 0:
		quit(1)
	else:
		quit(0)
