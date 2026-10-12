import re

def main():
    with open("scripts/entities/companion_base.gd", "r") as f:
        comp_b = f.read()

    comp_b_cb = """func _handle_combat(_delta: float) -> void:
	# Virtual hook for subclasses to implement specific attacks
	var p = get_tree().get_first_node_in_group("player")
	if p != null and p.has_meta("solar_flare_unlocked") and p.get_meta("solar_flare_unlocked"):
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e is Node2D and global_position.distance_to(e.global_position) <= 60.0:
				e.set_meta("marked_by_solar", true)"""

    comp_b = re.sub(r'func _handle_combat\(_delta: float\) -> void:\n\t# Virtual hook for subclasses to implement specific attacks\n\tpass', comp_b_cb, comp_b)

    with open("scripts/entities/companion_base.gd", "w") as f:
        f.write(comp_b)

    print("Fixed companion base")

if __name__ == "__main__":
    main()
