with open('tests/test_runner.gd', 'r') as f:
    content = f.read()

economy_runner = """	await _run_relic_tests()
	await _run_economy_tests()

	var elapsed_ms := Time.get_ticks_msec() - start_time
	_print_summary(elapsed_ms)"""

content = content.replace("""	await _run_relic_tests()

	var elapsed_ms := Time.get_ticks_msec() - start_time
	_print_summary(elapsed_ms)""", economy_runner)

economy_func = """func _run_relic_tests() -> void:
	if not ResourceLoader.exists("res://tests/test_relic_system.gd"):
		record_skip("Relic System Suite", "tests/test_relic_system.gd not found")
		return
	var RelicSuiteClass = load("res://tests/test_relic_system.gd")
	var relic_suite = RelicSuiteClass.new()
	if relic_suite.has_method("run_all"):
		await relic_suite.run_all(self)
	else:
		record_fail("Relic System Suite", "run_all method missing on test_relic_system")

func _run_economy_tests() -> void:
	if not ResourceLoader.exists("res://tests/test_economy_system.gd"):
		record_skip("Economy System Suite", "tests/test_economy_system.gd not found")
		return
	var EconomySuiteClass = load("res://tests/test_economy_system.gd")
	var economy_suite = EconomySuiteClass.new()
	if economy_suite.has_method("run_all"):
		await economy_suite.run_all(self)
	else:
		record_fail("Economy System Suite", "run_all method missing on test_economy_system")"""

content = content.replace("""func _run_relic_tests() -> void:
	if not ResourceLoader.exists("res://tests/test_relic_system.gd"):
		record_skip("Relic System Suite", "tests/test_relic_system.gd not found")
		return
	var RelicSuiteClass = load("res://tests/test_relic_system.gd")
	var relic_suite = RelicSuiteClass.new()
	if relic_suite.has_method("run_all"):
		await relic_suite.run_all(self)
	else:
		record_fail("Relic System Suite", "run_all method missing on test_relic_system")""", economy_func)

with open('tests/test_runner.gd', 'w') as f:
    f.write(content)
