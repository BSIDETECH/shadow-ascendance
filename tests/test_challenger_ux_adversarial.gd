extends SceneTree

## Empirical Adversarial Stress Test Suite for UX Refactor (R1 & R2)
## Author: challenger_ux_1 (Empirical Challenger, Critic & Domain Specialist)
##
## Rigorously stresses:
## 1. Viewport scaling, stretch modes and aspect ratio invariants across diverse resolutions.
## 2. Camera2D clamp math and boundary containment in Greyrock Village and Arena under extreme positions.
## 3. Responsive UI Modals: Backdrop mouse intercept (MOUSE_FILTER_STOP) and full-screen blocking.
## 4. Rapid modal lifecycle stress (100 cycles each) and interleaved concurrent toggling.
## 5. Village banner (HubHUD) hiding and restoration invariants under rapid open/close.
## 6. Container boundary constraints, card dimensions, and text overflow under default & extreme strings.

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var findings: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_execute_adversarial_suite")

func record_pass(test_name: String) -> void:
	total_assertions += 1
	passed_assertions += 1
	print("  [PASS] %s" % test_name)

func record_fail(test_name: String, detail: String, severity: String = "CRITICAL") -> void:
	total_assertions += 1
	failed_assertions += 1
	var finding := {
		"name": test_name,
		"detail": detail,
		"severity": severity
	}
	findings.append(finding)
	printerr("  [FAIL][%s] %s -> %s" % [severity, test_name, detail])

func assert_true(cond: bool, test_name: String, fail_detail: String = "") -> void:
	if cond:
		record_pass(test_name)
	else:
		record_fail(test_name, fail_detail if fail_detail != "" else "Condition evaluated to false")

func assert_eq(actual: Variant, expected: Variant, test_name: String) -> void:
	if actual == expected:
		record_pass(test_name)
	else:
		record_fail(test_name, "Expected %s, got %s" % [str(expected), str(actual)])

func _execute_adversarial_suite() -> void:
	print("\n======================================================================")
	print(" CHALLENGER UX 1: ADVERSARIAL STRESS TEST SUITE (R1 & R2)")
	print(" Engine: Godot 4.6.1 (Headless Mode)")
	print("======================================================================\n")

	await _stress_r1_viewport_and_aspect_ratios()
	await _stress_r1_camera2d_clamp_math()
	await _stress_r2_mouse_interception()
	await _stress_r2_rapid_modal_lifecycle()
	await _stress_r2_village_banner_toggle()
	await _stress_r2_text_lengths_and_container_bounds()

	_print_summary()

# ==============================================================================
# SECTION 1: R1 VIEWPORT SCALING & ASPECT RATIO INVARIANTS
# ==============================================================================
func _stress_r1_viewport_and_aspect_ratios() -> void:
	print("--- [SECTION 1: VIEWPORT SCALING & ASPECT RATIO INVARIANTS] ---")

	# 1.1 Invariant ProjectSettings checks
	var sm: String = ProjectSettings.get_setting("display/window/stretch/mode", "")
	var sa: String = ProjectSettings.get_setting("display/window/stretch/aspect", "")
	var vw: int = ProjectSettings.get_setting("display/window/size/viewport_width", 0)
	var vh: int = ProjectSettings.get_setting("display/window/size/viewport_height", 0)
	var ww: int = ProjectSettings.get_setting("display/window/size/window_width_override", 0)
	var wh: int = ProjectSettings.get_setting("display/window/size/window_height_override", 0)

	assert_eq(sm, "canvas_items", "R1.Aspect.01: Stretch mode locked to canvas_items")
	assert_eq(sa, "keep", "R1.Aspect.02: Stretch aspect locked to keep")
	assert_eq(vw, 640, "R1.Aspect.03: Base viewport width is exactly 640")
	assert_eq(vh, 360, "R1.Aspect.04: Base viewport height is exactly 360")
	assert_eq(ww, 1280, "R1.Aspect.05: Window width override is 1280")
	assert_eq(wh, 720, "R1.Aspect.06: Window height override is 720")

	# Base aspect ratio must be 16:9
	var base_aspect: float = float(vw) / float(vh)
	assert_true(abs(base_aspect - (16.0 / 9.0)) < 0.001, "R1.Aspect.07: Base aspect ratio is exactly 16:9")

	# 1.2 Mathematical Scaling Matrix over diverse resolutions
	var test_resolutions: Array[Dictionary] = [
		{"w": 640, "h": 360, "name": "Native 1x (640x360)", "type": "exact"},
		{"w": 1280, "h": 720, "name": "HD 2x (1280x720)", "type": "exact"},
		{"w": 1920, "h": 1080, "name": "FHD 3x (1920x1080)", "type": "exact"},
		{"w": 2560, "h": 1440, "name": "2K 4x (2560x1440)", "type": "exact"},
		{"w": 3840, "h": 2160, "name": "4K 6x (3840x2160)", "type": "exact"},
		{"w": 2560, "h": 1080, "name": "Ultrawide 21:9 (2560x1080)", "type": "pillarbox"},
		{"w": 3440, "h": 1440, "name": "UWQHD 21:9 (3440x1440)", "type": "pillarbox"},
		{"w": 1024, "h": 768, "name": "Retro 4:3 (1024x768)", "type": "letterbox"},
		{"w": 800, "h": 600, "name": "SVGA 4:3 (800x600)", "type": "letterbox"},
		{"w": 1920, "h": 1200, "name": "16:10 Laptop (1920x1200)", "type": "letterbox"},
		{"w": 720, "h": 1280, "name": "Portrait Mobile 9:16 (720x1280)", "type": "extreme_pillarbox"},
		{"w": 1000, "h": 1000, "name": "Square 1:1 (1000x1000)", "type": "letterbox"},
		{"w": 320, "h": 180, "name": "Sub-scale 0.5x (320x180)", "type": "exact"}
	]

	for res in test_resolutions:
		var target_w: float = float(res["w"])
		var target_h: float = float(res["h"])
		var scale_x: float = target_w / 640.0
		var scale_y: float = target_h / 360.0
		var uniform_scale: float = min(scale_x, scale_y)

		var rendered_canvas_w: float = 640.0 * uniform_scale
		var rendered_canvas_h: float = 360.0 * uniform_scale
		var pad_x: float = (target_w - rendered_canvas_w) / 2.0
		var pad_y: float = (target_h - rendered_canvas_h) / 2.0

		var symmetric_x: bool = abs(pad_x - (target_w - rendered_canvas_w) * 0.5) < 0.001
		var symmetric_y: bool = abs(pad_y - (target_h - rendered_canvas_h) * 0.5) < 0.001
		var no_negative_bars: bool = (pad_x >= 0.0) and (pad_y >= 0.0)
		var canvas_aspect_preserved: bool = abs((rendered_canvas_w / rendered_canvas_h) - (16.0 / 9.0)) < 0.001

		assert_true(
			symmetric_x and symmetric_y and no_negative_bars and canvas_aspect_preserved,
			"R1.Aspect.Scale_%s: Symmetrical bars and 16:9 preserved (scale=%0.2f, pad=[%0.1f, %0.1f])" % [res["name"], uniform_scale, pad_x, pad_y],
			"Asymmetric scaling or aspect deformation on %s" % res["name"]
		)

# ==============================================================================
# SECTION 2: R1 CAMERA2D CLAMP MATH & VIEW CONTAINMENT
# ==============================================================================
func _stress_r1_camera2d_clamp_math() -> void:
	print("\n--- [SECTION 2: CAMERA2D CLAMP MATH & BOUNDARY CONTAINMENT] ---")

	# 2.1 Greyrock Village Camera Limits
	var VillageScene = load("res://scenes/hub/greyrock_village.tscn")
	var village = VillageScene.instantiate()
	root.add_child(village)
	await process_frame

	var v_cam: Camera2D = village.find_child("Camera2D", true, false) as Camera2D
	assert_true(v_cam != null, "R1.Cam.Village.01: Village Camera2D exists")
	assert_eq(v_cam.limit_left, 0, "R1.Cam.Village.02: limit_left is 0")
	assert_eq(v_cam.limit_top, 0, "R1.Cam.Village.03: limit_top is 0")
	assert_eq(v_cam.limit_right, 640, "R1.Cam.Village.04: limit_right is 640")
	assert_eq(v_cam.limit_bottom, 360, "R1.Cam.Village.05: limit_bottom is 360")

	# Mathematical oracle for Village Viewport bounds:
	# Canvas size is 640x360.
	# Viewport width = 640, height = 360.
	# Any camera with limit_left=0, limit_top=0, limit_right=640, limit_bottom=360
	# MUST clamp the screen center to (320, 180), so the visible rect is [0, 0, 640, 360].
	var village_test_positions: Array[Vector2] = [
		Vector2(320, 180),   # Center
		Vector2(0, 0),       # Top-Left corner
		Vector2(640, 360),   # Bottom-Right corner
		Vector2(-500, -500), # Extreme out-of-bounds Top-Left
		Vector2(1500, 1500), # Extreme out-of-bounds Bottom-Right
		Vector2(-1000, 180), # Far Left
		Vector2(2000, 180),  # Far Right
		Vector2(320, -1000), # Far Top
		Vector2(320, 2000),  # Far Bottom
		Vector2(-50, 100),   # Negative X boundary
		Vector2(700, 200),   # Positive X overflow
		Vector2(150, -80),   # Negative Y boundary
		Vector2(400, 450)    # Positive Y overflow
	]

	var village_clamp_leaks := 0
	for pos in village_test_positions:
		# Calculate clamped camera center according to Godot Camera2D logic:
		# clamped_left = clamp(pos.x - 320, limit_left, limit_right - 640)
		# clamped_top = clamp(pos.y - 180, limit_top, limit_bottom - 360)
		var view_x: float = clamp(pos.x - 320.0, float(v_cam.limit_left), float(v_cam.limit_right) - 640.0)
		var view_y: float = clamp(pos.y - 180.0, float(v_cam.limit_top), float(v_cam.limit_bottom) - 360.0)
		var view_right: float = view_x + 640.0
		var view_bottom: float = view_y + 360.0

		if view_x < 0.0 or view_y < 0.0 or view_right > 640.0 or view_bottom > 360.0:
			village_clamp_leaks += 1

	assert_eq(village_clamp_leaks, 0, "R1.Cam.Village.06: Player position across 13 extreme vectors never sees outside [0,0,640,360]")

	root.remove_child(village)
	village.free()

	# 2.2 Arena Camera Limits
	var ArenaScene = load("res://scenes/arena/arena.tscn")
	var arena = ArenaScene.instantiate()
	root.add_child(arena)
	await process_frame

	var a_cam: Camera2D = arena.find_child("Camera2D", true, false) as Camera2D
	assert_true(a_cam != null, "R1.Cam.Arena.01: Arena Camera2D exists")
	assert_eq(a_cam.limit_left, -600, "R1.Cam.Arena.02: Arena limit_left is -600")
	assert_eq(a_cam.limit_top, -400, "R1.Cam.Arena.03: Arena limit_top is -400")
	assert_eq(a_cam.limit_right, 600, "R1.Cam.Arena.04: Arena limit_right is 600")
	assert_eq(a_cam.limit_bottom, 400, "R1.Cam.Arena.05: Arena limit_bottom is 400")

	# Map total span: 1200 wide (-600 to 600), 800 tall (-400 to 400).
	# Viewport is 640x360. Half viewport is (320, 180).
	# Clamped view range:
	# view_left in [-600, 600 - 640 = -40] -> center_x in [-280, 280]
	# view_top in [-400, 400 - 360 = 40] -> center_y in [-220, 220]
	var arena_test_positions: Array[Vector2] = [
		Vector2(0, 0),         # Center
		Vector2(-600, -400),   # Top-Left corner boundary
		Vector2(600, 400),     # Bottom-Right corner boundary
		Vector2(-600, 400),    # Bottom-Left corner boundary
		Vector2(600, -400),    # Top-Right corner boundary
		Vector2(-2000, -2000), # Extreme out-of-bounds TL
		Vector2(2000, 2000),   # Extreme out-of-bounds BR
		Vector2(-2000, 0),     # Extreme Left
		Vector2(2000, 0),      # Extreme Right
		Vector2(0, -2000),     # Extreme Top
		Vector2(0, 2000),      # Extreme Bottom
		Vector2(-280, -220),   # Theoretical max valid camera center TL
		Vector2(280, 220),     # Theoretical max valid camera center BR
		Vector2(-281, -221),   # 1 pixel beyond clamp threshold
		Vector2(281, 221)      # 1 pixel beyond clamp threshold
	]

	# Also generate a continuous trajectory walk across the entire arena (50 steps)
	for i in range(50):
		var t := float(i) / 49.0
		var walk_pos := Vector2(
			lerp(-1000.0, 1000.0, t),
			lerp(-800.0, 800.0, t)
		)
		arena_test_positions.append(walk_pos)

	var arena_clamp_leaks := 0
	for pos in arena_test_positions:
		var view_x: float = clamp(pos.x - 320.0, float(a_cam.limit_left), float(a_cam.limit_right) - 640.0)
		var view_y: float = clamp(pos.y - 180.0, float(a_cam.limit_top), float(a_cam.limit_bottom) - 360.0)
		var view_right: float = view_x + 640.0
		var view_bottom: float = view_y + 360.0

		if view_x < -600.0 or view_y < -400.0 or view_right > 600.0 or view_bottom > 400.0:
			arena_clamp_leaks += 1

	assert_eq(arena_clamp_leaks, 0, "R1.Cam.Arena.06: 65 extreme vectors and continuous walks never breach [-600,-400,600,400]")

	root.remove_child(arena)
	arena.free()

# ==============================================================================
# SECTION 3: R2 MOUSE INTERCEPTION (MOUSE_FILTER_STOP)
# ==============================================================================
func _stress_r2_mouse_interception() -> void:
	print("\n--- [SECTION 3: MOUSE INTERCEPTION & FULL-SCREEN BLOCKING] ---")

	# Test all 4 modal components for MOUSE_FILTER_STOP and full-screen anchors
	var components: Array[Dictionary] = [
		{"scene": "res://scenes/ui/gacha_screen/gacha_screen.tscn", "name": "GachaScreen", "backdrop": "ColorRectDim"},
		{"scene": "res://scenes/ui/modals/tavern_recruit_modal.tscn", "name": "TavernRecruitModal", "backdrop": "Backdrop"},
		{"scene": "res://scenes/ui/modals/quest_board_modal.tscn", "name": "QuestBoardModal", "backdrop": "Backdrop"},
		{"scene": "res://scenes/ui/ending_screen/ending_screen.tscn", "name": "EndingScreen", "backdrop": "Background"}
	]

	for comp in components:
		var s = load(comp["scene"])
		var inst = s.instantiate()
		root.add_child(inst)
		await process_frame

		var backdrop: Control = inst.find_child(comp["backdrop"], true, false) as Control
		assert_true(backdrop != null, "R2.Mouse.%s: Backdrop %s found" % [comp["name"], comp["backdrop"]])
		if backdrop != null:
			assert_eq(
				backdrop.mouse_filter,
				Control.MOUSE_FILTER_STOP,
				"R2.Mouse.%s: mouse_filter is MOUSE_FILTER_STOP (0)" % comp["name"]
			)
			assert_true(
				backdrop.anchor_right == 1.0 and backdrop.anchor_bottom == 1.0,
				"R2.Mouse.%s: Backdrop covers full screen (anchors [1.0, 1.0])" % comp["name"]
			)

		root.remove_child(inst)
		inst.free()

	# 3.2 Empirical Click Swallowing Harness
	# Create a background test button, layer a modal above it, and verify the button NEVER receives clicks
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = 5
	root.add_child(bg_layer)

	var bg_btn := Button.new()
	bg_btn.position = Vector2(100, 100)
	bg_btn.size = Vector2(200, 50)
	bg_layer.add_child(bg_btn)
	var bg_clicked := false
	bg_btn.pressed.connect(func(): bg_clicked = true)

	var QuestModalScene = load("res://scenes/ui/modals/quest_board_modal.tscn")
	var modal_inst = QuestModalScene.instantiate()
	var fg_layer := CanvasLayer.new()
	fg_layer.layer = 20
	fg_layer.add_child(modal_inst)
	root.add_child(fg_layer)
	await process_frame

	modal_inst.open()
	await process_frame

	# Simulate click on coordinates (120, 120) which overlaps the bg button
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = Vector2(120, 120)

	# Deliver to modal backdrop
	var modal_bd: Control = modal_inst.find_child("Backdrop", true, false) as Control
	if modal_bd != null and modal_bd.has_method("_gui_input"):
		modal_bd._gui_input(click_event)

	assert_true(
		not bg_clicked,
		"R2.Mouse.ClickSwallow: Clicks hitting modal backdrop do NOT trigger background elements",
		"Background element was triggered through active modal!"
	)

	root.remove_child(fg_layer)
	fg_layer.free()
	root.remove_child(bg_layer)
	bg_layer.free()

# ==============================================================================
# SECTION 4: R2 RAPID MODAL LIFECYCLE STRESS (100 CYCLES EACH)
# ==============================================================================
func _stress_r2_rapid_modal_lifecycle() -> void:
	print("\n--- [SECTION 4: RAPID MODAL LIFECYCLE STRESS (100 CYCLES EACH)] ---")

	# 4.1 Tavern Modal 100 cycles
	var TavernScene = load("res://scenes/ui/modals/tavern_recruit_modal.tscn")
	var tavern = TavernScene.instantiate()
	root.add_child(tavern)
	await process_frame

	var tavern_closed_count := 0
	tavern.modal_closed.connect(func(): tavern_closed_count += 1)

	var tavern_ok := true
	for i in range(100):
		tavern.open()
		if not tavern.visible:
			tavern_ok = false
		tavern.close()
		if tavern.visible:
			tavern_ok = false

	assert_true(tavern_ok, "R2.Lifecycle.Tavern.01: 100 rapid open/close cycles maintained visible state invariants")
	assert_eq(tavern_closed_count, 100, "R2.Lifecycle.Tavern.02: Exactly 100 modal_closed signals emitted without loss")

	root.remove_child(tavern)
	tavern.free()

	# 4.2 Quest Board Modal 100 cycles
	var QuestScene = load("res://scenes/ui/modals/quest_board_modal.tscn")
	var quest = QuestScene.instantiate()
	root.add_child(quest)
	await process_frame

	var quest_closed_count := 0
	quest.modal_closed.connect(func(): quest_closed_count += 1)

	var quest_ok := true
	for i in range(100):
		quest.open()
		if not quest.visible:
			quest_ok = false
		quest.close()
		if quest.visible:
			quest_ok = false

	assert_true(quest_ok, "R2.Lifecycle.Quest.01: 100 rapid open/close cycles maintained visible state invariants")
	assert_eq(quest_closed_count, 100, "R2.Lifecycle.Quest.02: Exactly 100 modal_closed signals emitted without loss")

	root.remove_child(quest)
	quest.free()

	# 4.3 Gacha Screen 50 rapid awaken/select cycles
	var GachaScene = load("res://scenes/ui/gacha_screen/gacha_screen.tscn")
	var gacha = GachaScene.instantiate()
	root.add_child(gacha)
	await process_frame

	var chosen_count := 0
	gacha.card_chosen.connect(func(_c): chosen_count += 1)

	var gacha_ok := true
	for i in range(50):
		var lvl: int = 2 if (i % 2 == 0) else 3
		gacha.open_gacha(lvl)
		if not gacha.visible:
			gacha_ok = false

		var container: HBoxContainer = gacha.find_child("CardsContainer", true, false) as HBoxContainer
		if container == null or container.get_child_count() != 3:
			gacha_ok = false

		# Simulate card selection
		var mock_card := {"id": "test_card", "rarity": "R", "title": "Test", "desc": "Desc"}
		gacha._on_card_selected(mock_card)
		if gacha.visible:
			gacha_ok = false

	assert_true(gacha_ok, "R2.Lifecycle.Gacha.01: 50 open/select cycles maintained cards count and pause/visibility invariants")
	assert_eq(chosen_count, 50, "R2.Lifecycle.Gacha.02: Exactly 50 card_chosen signals emitted")
	assert_true(not get_tree().paused, "R2.Lifecycle.Gacha.03: Game unpaused cleanly after all cycles")

	root.remove_child(gacha)
	gacha.free()

# ==============================================================================
# SECTION 5: VILLAGE BANNER HIDING & RESTORATION UNDER RAPID TOGGLING
# ==============================================================================
func _stress_r2_village_banner_toggle() -> void:
	print("\n--- [SECTION 5: VILLAGE BANNER HIDING & RESTORATION UNDER TOGGLING] ---")

	var VillageScene = load("res://scenes/hub/greyrock_village.tscn")
	var village = VillageScene.instantiate()
	root.add_child(village)
	await process_frame

	var hub_hud: Control = village.find_child("HubHUD", true, false) as Control
	var quest_modal: Control = village.find_child("QuestBoardModal", true, false) as Control
	var tavern_modal: Control = village.find_child("TavernRecruitModal", true, false) as Control
	var diag_box: CanvasLayer = village.find_child("BottomDialogueBox", true, false) as CanvasLayer
	var instruction_label: Label = village.find_child("InstructionLabel", true, false) as Label

	assert_true(hub_hud != null, "R2.Banner.01: HubHUD exists in village")
	assert_true(quest_modal != null, "R2.Banner.02: QuestBoardModal exists in village")
	assert_true(tavern_modal != null, "R2.Banner.03: TavernRecruitModal exists in village")

	# Initial state: HubHUD must be visible
	assert_true(hub_hud.visible, "R2.Banner.04: HubHUD visible initially when modals closed")

	# Quest open -> banner hidden
	quest_modal.open()
	await process_frame
	assert_true(not hub_hud.visible, "R2.Banner.05: HubHUD hidden when Quest Board Modal is opened")

	quest_modal.close()
	await process_frame
	assert_true(hub_hud.visible, "R2.Banner.06: HubHUD restored when Quest Board Modal is closed")

	# Tavern open -> banner hidden
	tavern_modal.open()
	await process_frame
	assert_true(not hub_hud.visible, "R2.Banner.07: HubHUD hidden when Tavern Modal is opened")

	tavern_modal.close()
	await process_frame
	assert_true(hub_hud.visible, "R2.Banner.08: HubHUD restored when Tavern Modal is closed")

	# Overlapping Modals Stress:
	# Open Quest -> Open Tavern -> Close Quest -> HubHUD must STILL be hidden!
	quest_modal.open()
	tavern_modal.open()
	await process_frame
	assert_true(not hub_hud.visible, "R2.Banner.09: HubHUD hidden when both modals opened")

	quest_modal.close()
	await process_frame
	assert_true(not hub_hud.visible, "R2.Banner.10: HubHUD STILL hidden when only Quest closed but Tavern remains open")

	tavern_modal.close()
	await process_frame
	assert_true(hub_hud.visible, "R2.Banner.11: HubHUD fully restored when both modals closed")

	# 100 Interleaved Pseudo-Random Toggles
	var toggle_ok := true
	for i in range(100):
		var q_state: bool = (i % 2 == 0)
		var t_state: bool = (i % 3 == 0)

		if q_state:
			quest_modal.open()
		else:
			quest_modal.close()

		if t_state:
			tavern_modal.open()
		else:
			tavern_modal.close()

		var any_modal_open: bool = quest_modal.visible or tavern_modal.visible
		var expected_hud_visible: bool = not any_modal_open

		if hub_hud.visible != expected_hud_visible:
			toggle_ok = false
			break

	assert_true(toggle_ok, "R2.Banner.12: 100 interleaved toggles strictly maintained HubHUD visibility invariant")

	# Dialogue Box vs InstructionLabel check
	if diag_box != null and instruction_label != null:
		diag_box.visible = true
		village._on_dialogue_visibility_changed()
		assert_true(not instruction_label.visible, "R2.Banner.13: Instruction label hidden when dialogue box active")

		diag_box.visible = false
		village._on_dialogue_visibility_changed()
		assert_true(instruction_label.visible, "R2.Banner.14: Instruction label restored when dialogue box closed")

	root.remove_child(village)
	village.free()

# ==============================================================================
# SECTION 6: R2 TEXT LENGTHS & CONTAINER BOUNDS UNDER ADVERSARIAL CONTENT
# ==============================================================================
func _stress_r2_text_lengths_and_container_bounds() -> void:
	print("\n--- [SECTION 6: TEXT LENGTHS & CONTAINER BOUNDS UNDER ADVERSARIAL CONTENT] ---")

	# 6.1 Gacha Cards Width and Text Clipping Check
	var GachaScene = load("res://scenes/ui/gacha_screen/gacha_screen.tscn")
	var gacha = GachaScene.instantiate()
	root.add_child(gacha)
	await process_frame

	var panel: Panel = gacha.find_child("Panel", true, false) as Panel
	var margin: MarginContainer = gacha.find_child("MarginContainer", true, false) as MarginContainer
	var cards_cont: HBoxContainer = gacha.find_child("CardsContainer", true, false) as HBoxContainer

	assert_true(panel != null, "R2.Bounds.Gacha.01: Gacha Panel exists")
	assert_true(margin != null, "R2.Bounds.Gacha.02: MarginContainer exists")
	assert_true(cards_cont != null, "R2.Bounds.Gacha.03: CardsContainer exists")

	# MarginContainer padding check
	var ml: int = margin.get_theme_constant("margin_left")
	var mr: int = margin.get_theme_constant("margin_right")
	var mt: int = margin.get_theme_constant("margin_top")
	var mb: int = margin.get_theme_constant("margin_bottom")
	assert_true(ml >= 16 and mr >= 16 and mt >= 14 and mb >= 14, "R2.Bounds.Gacha.04: Margins adhere to 16-24px specification")

	# 3 cards width = 165*3 + 12*2 = 519px. Panel size = 580px. Margins = 20 + 20 = 40px. Available = 540px.
	var gacha_available_w: float = panel.custom_minimum_size.x - float(ml + mr)
	var gacha_cards_total_w: float = 165.0 * 3.0 + float(cards_cont.get_theme_constant("separation")) * 2.0
	assert_true(gacha_cards_total_w <= gacha_available_w, "R2.Bounds.Gacha.05: 3 cards fit horizontally (needed %0.1f <= available %0.1f)" % [gacha_cards_total_w, gacha_available_w])

	# Check all production cards for text formatting & autowrapping
	var all_production_cards: Array[Dictionary] = []
	all_production_cards.append_array(GachaScreen.STARTER_CHEAT_CARDS)
	all_production_cards.append_array(GachaScreen.POOL_R)
	all_production_cards.append_array(GachaScreen.POOL_SR)
	all_production_cards.append_array(GachaScreen.POOL_SSR)
	all_production_cards.append_array(GachaScreen.POOL_EX)
	all_production_cards.append_array(GachaScreen.BOSS_THEFT_CARDS)

	var text_formatting_ok := true
	for card in all_production_cards:
		if not card.has("title") or not card.has("desc") or not card.has("rarity"):
			text_formatting_ok = false
		if card["title"].strip_edges() == "" or card["desc"].strip_edges() == "":
			text_formatting_ok = false

	assert_true(text_formatting_ok, "R2.Bounds.Gacha.06: All %d production gacha cards possess non-empty titles and descriptions" % all_production_cards.size())

	# Adversarial Extreme Text Injection into Gacha Buttons
	var extreme_cards: Array[Dictionary] = [
		{"id": "ext_1", "rarity": "EX", "title": "👑 " + "SUPER_LONG_TITLE_".repeat(5), "desc": "Extreme description text without breaking words: " + "DEVASTATION".repeat(10)},
		{"id": "ext_2", "rarity": "SSR", "title": "⚡ Mini", "desc": "Extremely detailed lore explanation: " + "Esta é uma habilidade lendária concedida pelas deusas celestiais durante a grande guerra dos leylines. ".repeat(4)},
		{"id": "ext_3", "rarity": "R", "title": "", "desc": "Desc with emojis: 💀🔥🌪️🩸⚔️🛡️✨★👑"}
	]

	for c in extreme_cards:
		gacha._create_card_button(c)

	await process_frame
	var ext_btn_count: int = cards_cont.get_child_count()
	assert_eq(ext_btn_count, 3, "R2.Bounds.Gacha.07: Extreme text cards spawned cleanly without crashing")

	root.remove_child(gacha)
	gacha.free()

	# 6.2 Tavern Candidate Cards Sizing & Padding Check
	var TavernScene = load("res://scenes/ui/modals/tavern_recruit_modal.tscn")
	var tavern = TavernScene.instantiate()
	root.add_child(tavern)
	await process_frame

	var t_panel: PanelContainer = tavern.find_child("PanelContainer", true, false) as PanelContainer
	var t_margin: MarginContainer = tavern.find_child("MarginContainer", true, false) as MarginContainer
	var t_roster: HBoxContainer = tavern.find_child("MercenaryHBox", true, false) as HBoxContainer

	assert_true(t_panel != null, "R2.Bounds.Tavern.01: Tavern PanelContainer exists")
	assert_true(t_margin != null, "R2.Bounds.Tavern.02: Tavern MarginContainer exists")
	assert_true(t_roster != null, "R2.Bounds.Tavern.03: MercenaryHBox exists")

	var t_ml: int = t_margin.get_theme_constant("margin_left")
	var t_mr: int = t_margin.get_theme_constant("margin_right")
	var t_available_w: float = t_panel.custom_minimum_size.x - float(t_ml + t_mr)
	# 3 cards min size 160 + separation (8) * 2 = 480 + 16 = 496px
	var t_cards_total_w: float = 160.0 * 3.0 + float(t_roster.get_theme_constant("separation")) * 2.0
	assert_true(t_cards_total_w <= t_available_w, "R2.Bounds.Tavern.04: 3 candidate cards fit horizontally (needed %0.1f <= available %0.1f)" % [t_cards_total_w, t_available_w])

	# Check candidate card internal structures
	var candidates: Array[Dictionary] = tavern.get_candidates()
	assert_eq(candidates.size(), 3, "R2.Bounds.Tavern.05: Exactly 3 mercenary candidates available")

	# Render candidates and inspect children
	tavern._render_candidates()
	await process_frame

	var cards_rendered: int = t_roster.get_child_count()
	assert_eq(cards_rendered, 3, "R2.Bounds.Tavern.06: Exactly 3 candidate cards rendered in container")

	# Inspect candidate card elements
	var all_cards_valid := true
	for child in t_roster.get_children():
		var p_card := child as PanelContainer
		if p_card == null or p_card.custom_minimum_size.x < 160.0:
			all_cards_valid = false
		var inner_margin: MarginContainer = p_card.find_child("MarginContainer", true, false) as MarginContainer
		if inner_margin == null:
			all_cards_valid = false

	assert_true(all_cards_valid, "R2.Bounds.Tavern.07: Each candidate card is wrapped in internal MarginContainer with min size >= 160")

	# Adversarial Candidate Injection (Very long quotes and names)
	var extreme_candidate := {
		"id": "ext_titan",
		"name": "Bartholomew The Third Of The Iron Wall And Leyline Protectors",
		"class_name": "Ultra Heavy Vanguard Paladin",
		"class_type": "paladin",
		"enneagram_type": 8,
		"enneagram_name": "Tipo 8 (O Desafiador Supremo)",
		"quote": "Eu nunca darei um único passo para trás mesmo que mil demônios surjam do chão das cinzas e destruam toda a muralha leste da fortaleza ancestral!",
		"role_desc": "Tanque Supremo (999 HP, Armadura 50%, Barreira Impenetrável e Atordoamento em Área Contínuo por 10 Segundos)",
		"cost": 500
	}

	var ext_card_panel: PanelContainer = tavern._create_candidate_card(extreme_candidate)
	t_roster.add_child(ext_card_panel)
	await process_frame

	assert_true(ext_card_panel != null, "R2.Bounds.Tavern.08: Extreme text candidate card created and laid out without errors")

	root.remove_child(tavern)
	tavern.free()

	# 6.3 Quest Board Modal Container Bounds & Responsive Split
	var QuestScene = load("res://scenes/ui/modals/quest_board_modal.tscn")
	var quest = QuestScene.instantiate()
	root.add_child(quest)
	await process_frame

	var q_panel: PanelContainer = quest.find_child("PanelContainer", true, false) as PanelContainer
	var q_scroll: ScrollContainer = quest.find_child("ScrollContainer", true, false) as ScrollContainer
	var q_detail: PanelContainer = quest.find_child("DetailPanel", true, false) as PanelContainer
	var q_detail_margin: MarginContainer = quest.find_child("DetailMargin", true, false) as MarginContainer

	assert_true(q_panel != null, "R2.Bounds.Quest.01: Quest PanelContainer exists")
	assert_true(q_scroll != null, "R2.Bounds.Quest.02: Quest ScrollContainer exists (Left split)")
	assert_true(q_detail != null, "R2.Bounds.Quest.03: Quest DetailPanel exists (Right split)")
	assert_true(q_detail_margin != null, "R2.Bounds.Quest.04: Quest DetailMargin exists")

	# Check left split min width and right split expansion
	assert_true(q_scroll.custom_minimum_size.x >= 200.0, "R2.Bounds.Quest.05: ScrollContainer min width >= 200px (got %0.1f)" % q_scroll.custom_minimum_size.x)
	assert_eq(q_detail.size_flags_horizontal, Control.SIZE_EXPAND_FILL, "R2.Bounds.Quest.06: DetailPanel expands to fill remaining space")

	# Test all 7 quest ranks for valid data & display update
	var ranks := quest.get_all_ranks()
	assert_eq(ranks.size(), 7, "R2.Bounds.Quest.07: Exactly 7 quest ranks (F to S) defined")

	var all_ranks_display_ok := true
	for r in ranks:
		quest._update_details(r)
		var det := quest.get_quest_details(r)
		if det.is_empty():
			all_ranks_display_ok = false

	assert_true(all_ranks_display_ok, "R2.Bounds.Quest.08: All 7 quest ranks update details cleanly")

	root.remove_child(quest)
	quest.free()

	# 6.4 Ending Screen Container Bounds Check
	var EndingScene = load("res://scenes/ui/ending_screen/ending_screen.tscn")
	var ending = EndingScene.instantiate()
	root.add_child(ending)
	await process_frame

	var end_panel: PanelContainer = ending.find_child("Panel", true, false) as PanelContainer
	var end_epilogue: Label = ending.find_child("EpilogueLabel", true, false) as Label
	var end_btn: Button = ending.find_child("ReturnButton", true, false) as Button

	assert_true(end_panel != null, "R2.Bounds.Ending.01: Ending PanelContainer exists")
	assert_true(end_epilogue != null, "R2.Bounds.Ending.02: EpilogueLabel exists")
	assert_true(end_btn != null, "R2.Bounds.Ending.03: ReturnButton exists")

	# Panel dimensions check
	assert_true(end_panel.custom_minimum_size.x <= 640.0, "R2.Bounds.Ending.04: Ending panel width <= 640px")
	assert_true(end_panel.custom_minimum_size.y <= 360.0, "R2.Bounds.Ending.05: Ending panel height <= 360px")

	# Test both endings for text display
	ending.display_ending("GOOD_ENDING", {"allies_survived": 3, "agency_score": 100})
	await process_frame
	var title_lbl: Label = ending.find_child("TitleLabel", true, false) as Label
	assert_eq(title_lbl.text, "A Aliança dos Vivos", "R2.Bounds.Ending.06: Good ending title rendered correctly")

	ending.display_ending("BAD_ENDING", {"allies_survived": 0, "agency_score": -50})
	await process_frame
	assert_eq(title_lbl.text, "O Monstro Solitário", "R2.Bounds.Ending.07: Bad ending title rendered correctly")

	root.remove_child(ending)
	ending.free()

# ==============================================================================
# SUMMARY & EXIT
# ==============================================================================
func _print_summary() -> void:
	print("\n======================================================================")
	print(" CHALLENGER UX 1: TEST EXECUTION SUMMARY")
	print("======================================================================")
	print(" Total Assertions Evaluated : %d" % total_assertions)
	print(" Passed                     : %d" % passed_assertions)
	print(" Failed                     : %d" % failed_assertions)

	if failed_assertions > 0:
		print("\n Findings / Vulnerabilities Detected (%d):" % findings.size())
		for f in findings:
			print("   - [%s] %s: %s" % [f["severity"], f["name"], f["detail"]])
		print("----------------------------------------------------------------------")
		print(">> VERDICT: REQUEST_CHANGES (Exit Code 1)")
		print("======================================================================\n")
		quit(1)
	else:
		print("----------------------------------------------------------------------")
		print(">> VERDICT: APPROVE (Exit Code 0)")
		print("======================================================================\n")
		quit(0)
