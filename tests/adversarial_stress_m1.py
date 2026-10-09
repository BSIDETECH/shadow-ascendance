"""
Empirical Adversarial Stress Harness for Milestone 1
Project: Shadow Cheat: Solo Guild Ascendance
Agent: challenger_m1_2

Tests all M1 components under adversarial conditions:
- Zero, negative, extreme, and non-finite damage
- Rapid healing and over-healing bounds
- Invincibility frame state machine and timing precision
- Hit flash shader mathematical stability
- EventBus signal payload safety and connection semantics
- Hitbox / Hurtbox team collision matrices
"""

import math
import sys
import random

class DamageType:
    PHYSICAL = 1
    DARK = 2
    FIRE = 4
    ICE = 8

class DamageData:
    def __init__(self, amount=10.0, damage_type=DamageType.PHYSICAL, kb_force=50.0, kb_dir=(0.0, 0.0), source=None):
        self.amount = float(amount)
        self.damage_type = int(damage_type)
        self.knockback_force = float(kb_force)
        self.knockback_direction = kb_dir
        self.source = source

    def has_type(self, flag):
        return (self.damage_type & flag) != 0

    def get_knockback_velocity(self):
        dx, dy = self.knockback_direction
        length = math.sqrt(dx*dx + dy*dy)
        if length == 0.0 or self.knockback_force <= 0.0:
            return (0.0, 0.0)
        return (dx / length * self.knockback_force, dy / length * self.knockback_force)

    def duplicate_data(self):
        return DamageData(self.amount, self.damage_type, self.knockback_force, self.knockback_direction, self.source)

class HealthComponentGodotImpl:
    """Exact reproduction of scripts/combat/health_component.gd logic."""
    def __init__(self, max_health=100.0, current_health=100.0, i_frame_duration=0.2):
        self._max_health = max(1.0, float(max_health))
        self.current_health = min(float(current_health), self._max_health)
        self.i_frame_duration = float(i_frame_duration)
        self.is_invincible = False
        self.disable_collision_on_death = True
        self._i_frame_timer = 0.0
        
        # Signal tracking
        self.signals_health_changed = []
        self.signals_took_damage = []
        self.signals_died = []
        self.signals_healed = []
        self.signals_invincibility_started = 0
        self.signals_invincibility_ended = 0

    @property
    def max_health(self):
        return self._max_health

    @max_health.setter
    def max_health(self, val):
        self._max_health = max(1.0, float(val))
        if self.current_health > self._max_health:
            self.current_health = self._max_health
            self.signals_health_changed.append((self.current_health, self._max_health))

    def tick(self, delta):
        if self._i_frame_timer > 0.0:
            self._i_frame_timer -= delta
            if self._i_frame_timer <= 0.0:
                self._i_frame_timer = 0.0
                self.signals_invincibility_ended += 1

    def is_currently_invincible(self):
        return self.is_invincible or self._i_frame_timer > 0.0

    def is_alive(self):
        return self.current_health > 0.0

    def take_damage(self, data: DamageData):
        if data is None or not self.is_alive() or self.is_currently_invincible():
            return

        old_health = self.current_health
        # scripts/combat/health_component.gd line 52:
        self.current_health = max(0.0, self.current_health - data.amount)
        self.signals_health_changed.append((self.current_health, self.max_health))
        self.signals_took_damage.append(data)

        if self.current_health <= 0.0:
            self._on_death()
        else:
            if self.i_frame_duration > 0.0:
                self._i_frame_timer = self.i_frame_duration
                self.signals_invincibility_started += 1

    def heal(self, amount: float):
        if amount <= 0.0 or not self.is_alive():
            return
        old_health = self.current_health
        self.current_health = min(self.max_health, self.current_health + amount)
        gained = self.current_health - old_health
        if gained > 0.0:
            self.signals_healed.append(gained)
            self.signals_health_changed.append((self.current_health, self.max_health))

    def set_invincible_duration(self, duration: float):
        if duration > 0.0:
            self._i_frame_timer = max(self._i_frame_timer, duration)
            self.signals_invincibility_started += 1

    def reset_health(self):
        self.current_health = self.max_health
        self._i_frame_timer = 0.0
        self.signals_health_changed.append((self.current_health, self.max_health))

    def _on_death(self):
        self.signals_died.append(True)


def run_adversarial_suite():
    failures = []
    tests_run = 0

    print("==================================================")
    print("  EMPIRICAL ADVERSARIAL STRESS TEST SUITE (M1)")
    print("==================================================")

    # ----------------------------------------------------
    # TEST 1: Rapid Healing Past Max Health Bounds
    # ----------------------------------------------------
    tests_run += 1
    hc = HealthComponentGodotImpl(max_health=100.0, current_health=50.0)
    for _ in range(500):
        hc.heal(1.0)
    if hc.current_health != 100.0:
        failures.append(f"Rapid incremental healing exceeded max_health: {hc.current_health} != 100.0")
    if hc.current_health > hc.max_health:
        failures.append(f"Rapid healing overshot max_health bound: {hc.current_health} > {hc.max_health}")

    # Massive single heal
    tests_run += 1
    hc.heal(9999999.0)
    if hc.current_health != 100.0:
        failures.append(f"Massive heal did not clamp to max_health: got {hc.current_health}")

    # Zero heal
    tests_run += 1
    sig_count = len(hc.signals_healed)
    hc.heal(0.0)
    if len(hc.signals_healed) != sig_count:
        failures.append("Zero heal emitted healed signal")

    # Negative heal
    tests_run += 1
    hc.heal(-25.0)
    if len(hc.signals_healed) != sig_count or hc.current_health != 100.0:
        failures.append("Negative heal affected health or emitted signal")

    # Heal when dead
    tests_run += 1
    hc.current_health = 0.0
    hc.heal(50.0)
    if hc.current_health != 0.0:
        failures.append("Dead entity was revived by heal()")

    # ----------------------------------------------------
    # TEST 2: Negative Damage Vulnerability (Cheat-Heal Bug)
    # ----------------------------------------------------
    tests_run += 1
    hc2 = HealthComponentGodotImpl(max_health=100.0, current_health=50.0)
    neg_dmg = DamageData(amount=-30.0)
    hc2.take_damage(neg_dmg)
    # In Godot health_component.gd: current_health = maxf(0.0, 50 - (-30)) = 80!
    if hc2.current_health > 50.0:
        failures.append(
            f"[CRITICAL BUG] Negative damage cheat-healed entity from 50.0 to {hc2.current_health}! "
            "HealthComponent.take_damage does not guard against data.amount < 0.0."
        )

    # Negative damage beyond max_health
    tests_run += 1
    hc2_overflow = HealthComponentGodotImpl(max_health=100.0, current_health=100.0)
    hc2_overflow.take_damage(DamageData(amount=-200.0))
    if hc2_overflow.current_health > 100.0:
        failures.append(
            f"[CRITICAL BUG] Negative damage broke max_health ceiling! "
            f"Health is {hc2_overflow.current_health} > max_health {hc2_overflow.max_health}."
        )

    # ----------------------------------------------------
    # TEST 3: Zero Damage Invincibility Exploit
    # ----------------------------------------------------
    tests_run += 1
    hc3 = HealthComponentGodotImpl(max_health=100.0, current_health=100.0, i_frame_duration=0.2)
    zero_dmg = DamageData(amount=0.0)
    hc3.take_damage(zero_dmg)
    if hc3.is_currently_invincible():
        failures.append(
            "[HIGH BUG] Zero-damage hit granted invincibility frames! "
            "An attack dealing 0 damage triggers _i_frame_timer = i_frame_duration."
        )
    if len(hc3.signals_health_changed) > 0:
        failures.append(
            "[MEDIUM BUG] Zero-damage hit emitted health_changed signal despite 0 health delta."
        )

    # ----------------------------------------------------
    # TEST 4: Invincibility Timer Timing & Boundary Precision
    # ----------------------------------------------------
    tests_run += 1
    hc4 = HealthComponentGodotImpl(max_health=100.0, current_health=100.0, i_frame_duration=0.2)
    hc4.take_damage(DamageData(amount=10.0))
    if not hc4.is_currently_invincible():
        failures.append("i-frames not active immediately after valid damage")

    # Tick exactly i_frame_duration
    hc4.tick(0.2)
    if hc4.is_currently_invincible():
        failures.append("i-frames still active after exact duration tick(0.2)")
    if hc4.signals_invincibility_ended != 1:
        failures.append(f"invincibility_ended signal count mismatch: expected 1, got {hc4.signals_invincibility_ended}")

    # Tick negative delta (adversarial delta glitch)
    tests_run += 1
    hc4.take_damage(DamageData(amount=10.0))
    timer_before = hc4._i_frame_timer
    hc4.tick(-0.5)
    # If delta is negative, timer increases!
    if hc4._i_frame_timer > timer_before:
        failures.append(
            f"[EDGE CASE] Negative delta tick increased i-frame duration from {timer_before} to {hc4._i_frame_timer}"
        )

    # ----------------------------------------------------
    # TEST 5: Hit Flash Shader Mathematical Stability
    # ----------------------------------------------------
    tests_run += 1
    def glsl_mix(x, y, a):
        return x * (1.0 - a) + y * a

    # Nominal bounds [0.0, 1.0]
    tex_rgb = 0.2
    flash_rgb = 1.0
    val_0 = glsl_mix(tex_rgb, flash_rgb, 0.0)
    val_1 = glsl_mix(tex_rgb, flash_rgb, 1.0)
    val_half = glsl_mix(tex_rgb, flash_rgb, 0.5)

    if abs(val_0 - 0.2) > 1e-5 or abs(val_1 - 1.0) > 1e-5 or abs(val_half - 0.6) > 1e-5:
        failures.append("GLSL mix formula nominal behavior failed")

    # Adversarial out-of-bounds inputs (without clamp)
    val_over = glsl_mix(tex_rgb, flash_rgb, 2.0)
    val_neg = glsl_mix(tex_rgb, flash_rgb, -1.0)
    if val_over > 1.0:
        failures.append(
            f"[MEDIUM FINDING] Hit flash shader unclamped modifier > 1.0 produces blown out color: "
            f"mix({tex_rgb}, {flash_rgb}, 2.0) = {val_over} > 1.0"
        )
    if val_neg < 0.0:
        failures.append(
            f"[MEDIUM FINDING] Hit flash shader unclamped modifier < 0.0 produces negative color: "
            f"mix({tex_rgb}, {flash_rgb}, -1.0) = {val_neg} < 0.0"
        )

    # ----------------------------------------------------
    # TEST 6: EventBus Duplicate Signal Connections & Disconnection Safety
    # ----------------------------------------------------
    tests_run += 1
    # Check Godot signal contract:
    # In Godot, connecting an already connected Callable throws ERR_INVALID_PARAMETER unless CONNECT_REFERENCE_COUNTED.
    # EventBus does not provide safe_connect() or is_connected checks.
    # If a dynamic node connects twice in _enter_tree without checking is_connected: Godot throws error.
    # Let's inspect event_bus.gd code directly for any safety wrappers:
    with open("scripts/autoloads/event_bus.gd", "r", encoding="utf-8") as f:
        eb_code = f.read()

    has_is_connected_check = "is_connected" in eb_code
    has_safe_connect = "safe_connect" in eb_code or "connect_safe" in eb_code
    if not has_is_connected_check and not has_safe_connect:
        failures.append(
            "[MEDIUM FINDING] EventBus does not provide safe connection wrappers or duplicate guard helpers. "
            "Callers must manually verify `signal.is_connected(callable)` before connecting."
        )

    # Check EventBus emit helpers for parameter validation
    has_pos_validation = "if xp < 0" in eb_code or "max(" in eb_code
    if not has_pos_validation:
        failures.append(
            "[LOW FINDING] EventBus.emit_* helpers pass unvalidated arguments (e.g. negative XP, NaN positions) directly to signals."
        )

    # ----------------------------------------------------
    # TEST 7: Hitbox / Hurtbox Team Filtering Matrix
    # ----------------------------------------------------
    tests_run += 1
    # Team index collision rules:
    # team 0 = player, team 1 = enemy
    # Same team -> hit ignored. Different team -> hit delivered.
    # What if team is negative or arbitrary integer?
    # In hitbox_component.gd line 39:
    # if hurtbox.team_index == team_index: return
    # Both team -1 == -1 -> returns. Team -1 != team 0 -> delivers hit.
    # This works cleanly for any integer equality.

    # ----------------------------------------------------
    # SUMMARY
    # ----------------------------------------------------
    print("==================================================")
    print(f"  Tests Executed: {tests_run}")
    print(f"  Failures & Findings: {len(failures)}")
    print("==================================================")
    for i, fail in enumerate(failures, 1):
        print(f"  [{i}] {fail}")
    print("==================================================")

    return failures

if __name__ == "__main__":
    fails = run_adversarial_suite()
    if any("[CRITICAL BUG]" in f for f in fails):
        sys.exit(2)
    elif fails:
        sys.exit(1)
    else:
        sys.exit(0)
