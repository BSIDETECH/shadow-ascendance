class_name TestEconomySystem
extends Node

## Testes unitários para validar a Economy System.

func run_all(runner: SceneTree) -> void:
	print("\n--- [ECONOMY SYSTEM TESTS] ---")
	test_initial_gold(runner)
	test_add_spend_gold(runner)
	test_recruit_insufficient_funds(runner)
	test_recruit_success(runner)

func test_initial_gold(runner: SceneTree) -> void:
	var gm = runner.root.get_node_or_null("GameManager")
	runner.call("assert_true", gm != null, "ECO.01: GameManager Exists")

	if gm != null:
		# Reset gold
		gm.set("player_gold", 0)
		runner.call("assert_eq", gm.get_gold(), 0, "ECO.02: Initial Gold is 0")

func test_add_spend_gold(runner: SceneTree) -> void:
	var gm = runner.root.get_node_or_null("GameManager")
	var eb = runner.root.get_node_or_null("EventBus")

	if gm != null and eb != null:
		var event_triggered = [false]
		var new_gold_amount = [0]

		var lambda = func(amt):
			event_triggered[0] = true
			new_gold_amount[0] = amt

		eb.gold_changed.connect(lambda)

		# Test Add
		gm.add_gold(100)
		runner.call("assert_eq", gm.get_gold(), 100, "ECO.03: Added 100 Gold Successfully")
		runner.call("assert_true", event_triggered[0], "ECO.04: EventBus.gold_changed emitted on Add")
		runner.call("assert_eq", new_gold_amount[0], 100, "ECO.05: EventBus emitted with correct amount")

		# Test Spend (Success)
		event_triggered[0] = false
		var spend_res = gm.spend_gold(50)
		runner.call("assert_true", spend_res, "ECO.06: Spend Gold 50 Successful")
		runner.call("assert_eq", gm.get_gold(), 50, "ECO.07: Deducted 50 Gold Successfully")
		runner.call("assert_true", event_triggered[0], "ECO.08: EventBus.gold_changed emitted on Spend")

		# Test Spend (Failure)
		event_triggered[0] = false
		spend_res = gm.spend_gold(100)
		runner.call("assert_false", spend_res, "ECO.09: Spend Gold 100 Failed due to insufficient funds")
		runner.call("assert_eq", gm.get_gold(), 50, "ECO.10: Gold balance remains unchanged on failure")
		runner.call("assert_false", event_triggered[0], "ECO.11: EventBus.gold_changed NOT emitted on failure")

		eb.gold_changed.disconnect(lambda)

func test_recruit_insufficient_funds(runner: SceneTree) -> void:
	var gm = runner.root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("player_gold", 0)
		gm.clear_party_roster()

		var ModalScene = load("res://scenes/ui/modals/tavern_recruit_modal.tscn")
		if ModalScene != null:
			var modal = ModalScene.instantiate() as Control
			runner.root.add_child(modal)

			var hire_success = modal.call("hire_candidate", "rogue_silas")
			runner.call("assert_false", hire_success, "ECO.12: Recruitment rejected due to insufficient gold")
			runner.call("assert_eq", gm.get_active_party_roster().size(), 0, "ECO.13: Active Party remains 0")

			modal.free()
		else:
			runner.call("record_skip", "ECO.12: Tavern modal scene not found", "Could not load res://scenes/ui/modals/tavern_recruit_modal.tscn")

func test_recruit_success(runner: SceneTree) -> void:
	var gm = runner.root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("player_gold", 500)
		gm.clear_party_roster()

		var ModalScene = load("res://scenes/ui/modals/tavern_recruit_modal.tscn")
		if ModalScene != null:
			var modal = ModalScene.instantiate() as Control
			runner.root.add_child(modal)

			var hire_success = modal.call("hire_candidate", "rogue_silas")
			runner.call("assert_true", hire_success, "ECO.14: Recruitment successful with sufficient gold")
			runner.call("assert_eq", gm.get_active_party_roster().size(), 1, "ECO.15: Silas added to active party")
			runner.call("assert_eq", gm.get_gold(), 370, "ECO.16: Silas cost (130) deducted correctly")

			modal.free()
		else:
			runner.call("record_skip", "ECO.14: Tavern modal scene not found", "Could not load res://scenes/ui/modals/tavern_recruit_modal.tscn")
