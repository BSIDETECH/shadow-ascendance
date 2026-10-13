extends SceneTree

func _init():
    var rogue_script = load("res://scripts/entities/companion_rogue.gd")
    var rogue = rogue_script.new()
    var root = Node2D.new()
    root.add_child(rogue)

    # We can't really do physics queries easily without a running physics server and MainLoop.
    # Wait, SceneTree runs in the main loop, but physics needs a window/viewport.
    print("Benchmark prepared")
    quit()
