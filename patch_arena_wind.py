import re

def main():
    filepath = "scripts/arena/arena.gd"
    with open(filepath, "r") as f:
        content = f.read()

    wind = """		"wind_momentum":
			player.wind_momentum_unlocked = true
			player.move_speed_mult += 0.20 # FIX: Adicionar movespeed"""
    content = content.replace('		"wind_momentum":\n\t\t\tplayer.wind_momentum_unlocked = true', wind)
    with open(filepath, "w") as f:
        f.write(content)

if __name__ == "__main__":
    main()
