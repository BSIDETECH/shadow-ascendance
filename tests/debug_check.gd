extends SceneTree

func _init() -> void:
	var BaseClass = load("res://scripts/entities/companion_base.gd")
	var base = BaseClass.new()
	print("before add_child motion_mode: ", base.motion_mode)
	root.add_child(base)
	print("after add_child motion_mode: ", base.motion_mode)
	print("health_comp: ", base.health_component)
	print("is took_damage connected: ", base.health_component.took_damage.is_connected(base._on_health_took_damage))
	var damaged_signal_fired := false
	base.ally_damaged.connect(func(amt):
		print("ally_damaged fired! amt=", amt)
		damaged_signal_fired = true
	)
	var test_data := DamageData.new(10.0, DamageData.DamageType.PHYSICAL)
	base.health_component.take_damage(test_data)
	print("damaged_signal_fired: ", damaged_signal_fired)
	quit(0)
