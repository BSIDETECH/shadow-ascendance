extends SceneTree

## Dedicated UX Refactor Test Suite (R1 - R5)
## Validates Viewport limits, Responsive UI Modals, Bottom Dialogue Box,
## Greyrock Village Level Design, and Arena Atmosphere.

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func _init() -> void:
	call_deferred("_run_ux_tests")

func assert_true(cond: bool, test_name: String) -> void:
	total_tests += 1
	if cond:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_tests += 1
		printerr("  [FAIL] %s" % test_name)

func assert_eq(actual: Variant, expected: Variant, test_name: String) -> void:
	total_tests += 1
	if actual == expected:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_tests += 1
		printerr("  [FAIL] %s: Expected %s, got %s" % [test_name, str(expected), str(actual)])

func _run_ux_tests() -> void:
	print("\n======================================================================")
	print(" UX REFACTOR VERIFICATION SUITE (R1 - R5)")
	print("======================================================================\n")

	# --- R1: Viewport & Camera Limits ---
	print("--- [R1: VIEWPORT & CAMERA LIMITS] ---")
	var stretch_mode: String = ProjectSettings.get_setting("display/window/stretch/mode", "")
	var stretch_aspect: String = ProjectSettings.get_setting("display/window/stretch/aspect", "")
	var vp_width: int = ProjectSettings.get_setting("display/window/size/viewport_width", 0)
	var vp_height: int = ProjectSettings.get_setting("display/window/size/viewport_height", 0)
	var win_w_override: int = ProjectSettings.get_setting("display/window/size/window_width_override", 0)
	var win_h_override: int = ProjectSettings.get_setting("display/window/size/window_height_override", 0)

	assert_eq(stretch_mode, "canvas_items", "R1.01: Stretch mode is canvas_items")
	assert_eq(stretch_aspect, "keep", "R1.02: Stretch aspect is keep")
	assert_eq(vp_width, 640, "R1.03: Viewport width is 640")
	assert_eq(vp_height, 360, "R1.04: Viewport height is 360")
	assert_eq(win_w_override, 1280, "R1.05: Window width override is 1280")
	assert_eq(win_h_override, 720, "R1.06: Window height override is 720")

	var VillageScene = load("res://scenes/hub/greyrock_village.tscn")
	var village = VillageScene.instantiate()
	root.add_child(village)
	await process_frame

	var v_cam: Camera2D = village.find_child("Camera2D", true, false) as Camera2D
	assert_true(v_cam != null, "R1.07: Village Camera2D exists")
	if v_cam != null:
		assert_eq(v_cam.limit_left, 0, "R1.08: Village Camera limit_left is 0")
		assert_eq(v_cam.limit_top, 0, "R1.09: Village Camera limit_top is 0")
		assert_eq(v_cam.limit_right, 640, "R1.10: Village Camera limit_right is 640")
		assert_eq(v_cam.limit_bottom, 360, "R1.11: Village Camera limit_bottom is 360")

	root.remove_child(village)
	village.free()

	var ArenaScene = load("res://scenes/arena/arena.tscn")
	var arena = ArenaScene.instantiate()
	root.add_child(arena)
	await process_frame

	var a_cam: Camera2D = arena.find_child("Camera2D", true, false) as Camera2D
	assert_true(a_cam != null, "R1.12: Arena Camera2D exists")
	if a_cam != null:
		assert_eq(a_cam.limit_left, -600, "R1.13: Arena Camera limit_left is -600")
		assert_eq(a_cam.limit_top, -400, "R1.14: Arena Camera limit_top is -400")
		assert_eq(a_cam.limit_right, 600, "R1.15: Arena Camera limit_right is 600")
		assert_eq(a_cam.limit_bottom, 400, "R1.16: Arena Camera limit_bottom is 400")

	root.remove_child(arena)
	arena.free()

	# --- R2: Responsive UI Modals & Containers ---
	print("\n--- [R2: RESPONSIVE UI MODALS & CONTAINERS] ---")
	var GachaScene = load("res://scenes/ui/gacha_screen/gacha_screen.tscn")
	var gacha = GachaScene.instantiate()
	root.add_child(gacha)
	await process_frame

	var gacha_dim: ColorRect = gacha.find_child("ColorRectDim", true, false) as ColorRect
	assert_true(gacha_dim != null and gacha_dim.mouse_filter == Control.MOUSE_FILTER_STOP, "R2.01: Gacha backdrop intercepts mouse events")
	var gacha_margin: MarginContainer = gacha.find_child("MarginContainer", true, false) as MarginContainer
	assert_true(gacha_margin != null, "R2.02: Gacha content wrapped in MarginContainer")
	root.remove_child(gacha)
	gacha.free()

	var TavernScene = load("res://scenes/ui/modals/tavern_recruit_modal.tscn")
	var tavern = TavernScene.instantiate()
	root.add_child(tavern)
	await process_frame

	var tavern_dim: ColorRect = tavern.find_child("Backdrop", true, false) as ColorRect
	assert_true(tavern_dim != null and tavern_dim.mouse_filter == Control.MOUSE_FILTER_STOP, "R2.03: Tavern backdrop intercepts mouse events")
	var tavern_margin: MarginContainer = tavern.find_child("MarginContainer", true, false) as MarginContainer
	assert_true(tavern_margin != null, "R2.04: Tavern content wrapped in MarginContainer")
	root.remove_child(tavern)
	tavern.free()

	var QuestScene = load("res://scenes/ui/modals/quest_board_modal.tscn")
	var quest = QuestScene.instantiate()
	root.add_child(quest)
	await process_frame

	var quest_dim: ColorRect = quest.find_child("Backdrop", true, false) as ColorRect
	assert_true(quest_dim != null and quest_dim.mouse_filter == Control.MOUSE_FILTER_STOP, "R2.05: Quest Board backdrop intercepts mouse events")
	var quest_margin: MarginContainer = quest.find_child("MarginContainer", true, false) as MarginContainer
	assert_true(quest_margin != null, "R2.06: Quest Board content wrapped in MarginContainer")
	var detail_margin: MarginContainer = quest.find_child("DetailMargin", true, false) as MarginContainer
	assert_true(detail_margin != null, "R2.07: Quest DetailPanel wrapped in MarginContainer")
	root.remove_child(quest)
	quest.free()

	var EndingScene = load("res://scenes/ui/ending_screen/ending_screen.tscn")
	var ending = EndingScene.instantiate()
	root.add_child(ending)
	await process_frame

	var end_bg: ColorRect = ending.find_child("Background", true, false) as ColorRect
	assert_true(end_bg != null and end_bg.mouse_filter == Control.MOUSE_FILTER_STOP, "R2.08: Ending Screen background intercepts mouse events")
	root.remove_child(ending)
	ending.free()

	# --- R3: Classic RPG Bottom Dialogue Box ---
	print("\n--- [R3: CLASSIC RPG BOTTOM DIALOGUE BOX] ---")
	assert_true(ResourceLoader.exists("res://scenes/ui/dialogue/bottom_dialogue_box.tscn"), "R3.01: Bottom dialogue box scene exists")
	assert_true(ResourceLoader.exists("res://scripts/ui/dialogue/bottom_dialogue_box.gd"), "R3.02: Bottom dialogue box script exists")

	var DlgScene = load("res://scenes/ui/dialogue/bottom_dialogue_box.tscn")
	var dlg = DlgScene.instantiate()
	root.add_child(dlg)
	await process_frame

	var completed := [false]
	dlg.show_dialogue("Guia de Teste", "Mensagem de teste para validacao da caixa de dialogo inferior.", func(): completed[0] = true)
	assert_true(dlg.visible, "R3.03: Bottom dialogue box opens and becomes visible")
	var spk_lbl: Label = dlg.find_child("SpeakerLabel", true, false) as Label
	assert_true(spk_lbl != null and spk_lbl.text == "Guia de Teste", "R3.04: Speaker label displays highlighted name")

	# Skip typewriter animation
	dlg.advance_dialogue()
	await process_frame
	# Advance to close
	dlg.advance_dialogue()
	await process_frame
	assert_true(not dlg.visible and completed[0], "R3.05: Dialogue advances, completes callback, and closes cleanly")

	root.remove_child(dlg)
	dlg.free()

	# --- R4: Organic Village Level Design ---
	print("\n--- [R4: GREYROCK VILLAGE LEVEL DESIGN] ---")
	village = VillageScene.instantiate()
	root.add_child(village)
	await process_frame

	var env = village.find_child("Environment", true, false)
	assert_true(env != null, "R4.01: Village Environment node exists")
	assert_true(env.find_child("EarthenGround", true, false) != null, "R4.02: Earthen soil ground base exists")
	assert_true(env.find_child("CobblestonePlaza", true, false) != null, "R4.03: Cobblestone central plaza exists")
	assert_true(env.find_child("GuildHouseWall", true, false) != null, "R4.04: Guild house stone walls exist")
	assert_true(env.find_child("TavernHouseWall", true, false) != null, "R4.05: Tavern house stone walls exist")
	assert_true(env.find_child("SanctuaryAltar", true, false) != null, "R4.06: Madre Selene sanctuary altar exists")

	var hud: Control = village.find_child("HubHUD", true, false) as Control
	var q_modal: Control = village.find_child("QuestBoardModal", true, false) as Control
	assert_true(hud != null and q_modal != null, "R4.07: HubHUD and QuestBoardModal exist in village")
	if hud != null and q_modal != null:
		q_modal.open()
		await process_frame
		assert_true(not hud.visible, "R4.08: HubHUD banner is hidden when Quest Board Modal is open")
		q_modal.close()
		await process_frame
		assert_true(hud.visible, "R4.09: HubHUD banner is restored when Quest Board Modal is closed")

	root.remove_child(village)
	village.free()

	# --- R5: Arena Atmosphere & Stones ---
	print("\n--- [R5: ARENA ATMOSPHERE & STONES] ---")
	arena = ArenaScene.instantiate()
	root.add_child(arena)
	await process_frame

	var floor_rect: TextureRect = arena.find_child("Floor", true, false) as TextureRect
	assert_true(floor_rect != null, "R5.01: Arena Floor node exists")
	if floor_rect != null and floor_rect.texture != null:
		assert_true(floor_rect.texture.resource_path.find("tile_0037.png") != -1, "R5.02: Arena floor uses seamless stone slab tile_0037")
		assert_true(floor_rect.modulate.r > 0.8 and floor_rect.modulate.b < 0.85, "R5.03: Arena floor has warm ancient stone modulate (not blue test grid)")

	var walls = arena.find_child("PerimeterWalls", true, false)
	assert_true(walls != null, "R5.04: Arena perimeter masonry walls exist")
	var torches = arena.find_child("AtmosphereTorches", true, false)
	assert_true(torches != null and torches.get_child_count() >= 20, "R5.05: Arena atmosphere sconce torches and braziers exist (>20 lights)")

	root.remove_child(arena)
	arena.free()

	print("\n======================================================================")
	print(" UX REFACTOR RESULTS: %d/%d Passed | %d Failed" % [passed_tests, total_tests, failed_tests])
	print("======================================================================\n")

	if failed_tests > 0:
		quit(1)
	else:
		quit(0)
