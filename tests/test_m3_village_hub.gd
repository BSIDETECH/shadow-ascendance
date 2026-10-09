extends SceneTree

## Dedicated Entrypoint for Headless Execution of Milestone 3 Tests.
## Command: & "Godot_console.exe" --headless --path . -s res://tests/test_m3_village_hub.gd

func _init() -> void:
	call_deferred("_start_tests")

func _start_tests() -> void:
	print("\n" + "=".repeat(70))
	print(" SHADOW CHEAT: SOLO GUILD ASCENDANCE — M3 STANDALONE RUNNER")
	print(" Milestone 3: Greyrock Village Hub & Barnaby's Tavern")
	print(" Engine: Godot 4.6.1 (Headless Mode)")
	print("=".repeat(70))

	var SuiteClass = load("res://tests/test_m3_village_hub_suite.gd")
	var suite = SuiteClass.new()
	await suite.run_all(self)

	print("\n" + "=".repeat(70))
	print(" M3 STANDALONE RESULTS")
	print(" Total Assertions: %d" % suite.total_assertions)
	print(" Passed          : %d" % suite.passed_assertions)
	print(" Failed          : %d" % suite.failed_assertions)
	print("=".repeat(70))

	if suite.exit_code == 0:
		print(">> RESULT: PASSED (Exit Code 0)\n")
		quit(0)
	else:
		printerr(">> RESULT: FAILED (Exit Code 1)\n")
		quit(1)
