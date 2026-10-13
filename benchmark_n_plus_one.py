import time
import math
import random

class Node2D:
    def __init__(self, x, y, is_enemy=False):
        self.x = x
        self.y = y
        self.is_enemy = is_enemy
        self.valid = True

    def distance_to(self, other):
        return math.hypot(self.x - other.x, self.y - other.y)

# Generate 10000 entities
entities = [Node2D(random.uniform(0, 10000), random.uniform(0, 10000), is_enemy=True) for _ in range(10000)]
# Add a rogue at (5000, 5000)
rogue = Node2D(5000, 5000)
dagger_range = 40.0

def test_n_plus_one():
    # Simulate get_nodes_in_group
    enemies = [e for e in entities if e.is_enemy]

    hits = 0
    start = time.time()
    for _ in range(100): # simulate 100 attacks
        for e in enemies:
            if e.valid:
                dist = rogue.distance_to(e)
                if dist <= dagger_range:
                    hits += 1
    return time.time() - start

# Simulate spatial partition / intersect_shape by pre-filtering
def test_spatial():
    # Build a simple grid to act like a physics server
    grid = {}
    cell_size = 100
    for e in entities:
        if e.is_enemy:
            cx, cy = int(e.x // cell_size), int(e.y // cell_size)
            grid.setdefault((cx, cy), []).append(e)

    hits = 0
    start = time.time()
    for _ in range(100):
        # Query
        rcx, rcy = int(rogue.x // cell_size), int(rogue.y // cell_size)
        results = []
        for dx in [-1, 0, 1]:
            for dy in [-1, 0, 1]:
                results.extend(grid.get((rcx + dx, rcy + dy), []))

        for e in results:
            if e.valid:
                dist = rogue.distance_to(e)
                if dist <= dagger_range:
                    hits += 1
    return time.time() - start

t1 = test_n_plus_one()
t2 = test_spatial()

print(f"O(N) global query time: {t1:.4f}s")
print(f"Spatial query time: {t2:.4f}s")
print(f"Speedup: {t1/t2:.1f}x")
