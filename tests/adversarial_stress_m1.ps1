# Empirical Adversarial Stress Test Harness in PowerShell
# Milestone 1 Verification: Shadow Cheat: Solo Guild Ascendance
# Agent: challenger_m1_2

Write-Host "=================================================="
Write-Host "  M1 EMPIRICAL ADVERSARIAL STRESS SUITE (PowerShell / .NET)"
Write-Host "=================================================="

$failures = @()
$testsRun = 0

# ----------------------------------------------------
# HealthComponent Simulation Class
# ----------------------------------------------------
class DamageDataSim {
    [double]$Amount = 10.0
    [int]$DamageType = 1
    [double]$KnockbackForce = 50.0

    DamageDataSim([double]$amt) {
        $this.Amount = $amt
        $this.DamageType = 1
        $this.KnockbackForce = 50.0
    }

    DamageDataSim([double]$amt, [int]$type, [double]$kb) {
        $this.Amount = $amt
        $this.DamageType = $type
        $this.KnockbackForce = $kb
    }
}

class HealthComponentSim {
    [double]$MaxHealth = 100.0
    [double]$CurrentHealth = 100.0
    [double]$IFrameDuration = 0.2
    [bool]$IsInvincible = $false
    [double]$IFrameTimer = 0.0

    [System.Collections.ArrayList]$SignalsHealthChanged = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList]$SignalsTookDamage = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList]$SignalsDied = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList]$SignalsHealed = [System.Collections.ArrayList]::new()
    [int]$InvincibilityStartedCount = 0
    [int]$InvincibilityEndedCount = 0

    HealthComponentSim([double]$maxHp, [double]$currHp, [double]$iframe) {
        $this.MaxHealth = [Math]::Max(1.0, $maxHp)
        $this.CurrentHealth = [Math]::Min($currHp, $this.MaxHealth)
        $this.IFrameDuration = $iframe
    }

    HealthComponentSim([double]$maxHp, [double]$currHp) {
        $this.MaxHealth = [Math]::Max(1.0, $maxHp)
        $this.CurrentHealth = [Math]::Min($currHp, $this.MaxHealth)
        $this.IFrameDuration = 0.2
    }

    [bool] IsCurrentlyInvincible() {
        return ($this.IsInvincible -or ($this.IFrameTimer -gt 0.0))
    }

    [bool] IsAlive() {
        return ($this.CurrentHealth -gt 0.0)
    }

    [void] Tick([double]$delta) {
        if ($this.IFrameTimer -gt 0.0) {
            $this.IFrameTimer -= $delta
            if ($this.IFrameTimer -le 0.0) {
                $this.IFrameTimer = 0.0
                $this.InvincibilityEndedCount++
            }
        }
    }

    # EXACT Godot implementation of take_damage from scripts/combat/health_component.gd
    [void] TakeDamage([DamageDataSim]$data) {
        if ($null -eq $data -or (-not $this.IsAlive()) -or $this.IsCurrentlyInvincible()) {
            return
        }

        # GDScript line 52: current_health = maxf(0.0, current_health - data.amount)
        $this.CurrentHealth = [Math]::Max(0.0, $this.CurrentHealth - $data.Amount)
        [void]$this.SignalsHealthChanged.Add(@($this.CurrentHealth, $this.MaxHealth))
        [void]$this.SignalsTookDamage.Add($data)

        if ($this.CurrentHealth -le 0.0) {
            [void]$this.SignalsDied.Add($true)
        } else {
            if ($this.IFrameDuration -gt 0.0) {
                $this.IFrameTimer = $this.IFrameDuration
                $this.InvincibilityStartedCount++
            }
        }
    }

    # EXACT Godot implementation of heal from scripts/combat/health_component.gd
    [void] Heal([double]$amount) {
        if ($amount -le 0.0 -or (-not $this.IsAlive())) {
            return
        }
        $oldHealth = $this.CurrentHealth
        $this.CurrentHealth = [Math]::Min($this.MaxHealth, $this.CurrentHealth + $amount)
        $gained = $this.CurrentHealth - $oldHealth
        if ($gained -gt 0.0) {
            [void]$this.SignalsHealed.Add($gained)
            [void]$this.SignalsHealthChanged.Add(@($this.CurrentHealth, $this.MaxHealth))
        }
    }
}

# ==============================================================================
# TEST SUITE 1: Rapid Healing & Bound Clamping
# ==============================================================================
$testsRun++
$hc1 = [HealthComponentSim]::new(100.0, 50.0)
for ($i = 0; $i -lt 1000; $i++) {
    $hc1.Heal(1.0)
}
if ($hc1.CurrentHealth -ne 100.0) {
    $failures += "[FAIL] Rapid healing did not stop at 100.0, got $($hc1.CurrentHealth)"
} else {
    Write-Host "  [PASS] Rapid incremental healing clamps strictly at max_health ($($hc1.CurrentHealth))"
}

$testsRun++
$hc1.Heal(999999.0)
if ($hc1.CurrentHealth -gt 100.0) {
    $failures += "[FAIL] Overhealing exceeded max_health: $($hc1.CurrentHealth)"
} else {
    Write-Host "  [PASS] Overhealing does not exceed max_health"
}

$testsRun++
$sigCount = $hc1.SignalsHealed.Count
$hc1.Heal(0.0)
$hc1.Heal(-50.0)
if ($hc1.SignalsHealed.Count -ne $sigCount) {
    $failures += "[FAIL] Zero or negative heal triggered healed signal"
} else {
    Write-Host "  [PASS] Zero and negative heal ignored cleanly"
}

$testsRun++
$hcDead = [HealthComponentSim]::new(100.0, 0.0)
$hcDead.Heal(50.0)
if ($hcDead.CurrentHealth -ne 0.0) {
    $failures += "[FAIL] Dead entity was revived by Heal()"
} else {
    Write-Host "  [PASS] Dead entity cannot be revived via Heal()"
}

# ==============================================================================
# TEST SUITE 2: Negative Damage / Cheat-Heal Exploit
# ==============================================================================
$testsRun++
$hcCheat = [HealthComponentSim]::new(100.0, 50.0)
$dmgNeg = [DamageDataSim]::new(-30.0)
$hcCheat.TakeDamage($dmgNeg)

if ($hcCheat.CurrentHealth -gt 50.0) {
    $failures += "[CRITICAL BUG] Negative damage cheat-healed entity from 50.0 to $($hcCheat.CurrentHealth)! HealthComponent.take_damage lacks check for data.amount <= 0.0."
    Write-Host "  [FAIL CRITICAL BUG] Negative damage cheat-healed entity from 50.0 to $($hcCheat.CurrentHealth)"
} else {
    Write-Host "  [PASS] Negative damage safely rejected"
}

$testsRun++
$hcOverflow = [HealthComponentSim]::new(100.0, 100.0)
$dmgOverflow = [DamageDataSim]::new(-500.0)
$hcOverflow.TakeDamage($dmgOverflow)

if ($hcOverflow.CurrentHealth -gt 100.0) {
    $failures += "[CRITICAL BUG] Negative damage caused current_health ($($hcOverflow.CurrentHealth)) to overflow max_health ($($hcOverflow.MaxHealth))!"
    Write-Host "  [FAIL CRITICAL BUG] Current health ($($hcOverflow.CurrentHealth)) exceeded max_health ($($hcOverflow.MaxHealth))"
} else {
    Write-Host "  [PASS] Max health upper bound respected on negative damage"
}

# ==============================================================================
# TEST SUITE 3: Zero Damage Invincibility Exploit
# ==============================================================================
$testsRun++
$hcZero = [HealthComponentSim]::new(100.0, 100.0, 0.2)
$dmgZero = [DamageDataSim]::new(0.0)
$hcZero.TakeDamage($dmgZero)

if ($hcZero.IsCurrentlyInvincible()) {
    $failures += "[HIGH BUG] Zero-damage hit granted invincibility frames! Entity became invincible after taking 0 damage."
    Write-Host "  [FAIL HIGH BUG] Zero damage granted invincibility frames"
} else {
    Write-Host "  [PASS] Zero damage does not trigger invincibility"
}

# ==============================================================================
# TEST SUITE 4: i-Frame Timing Precision & Clock Skew
# ==============================================================================
$testsRun++
$hcTimer = [HealthComponentSim]::new(100.0, 100.0, 0.2)
$hcTimer.TakeDamage([DamageDataSim]::new(10.0))
$hcTimer.Tick(0.1)
$stillInvuln = $hcTimer.IsCurrentlyInvincible()
$hcTimer.Tick(0.1) # reaches 0.2
$expiredInvuln = (-not $hcTimer.IsCurrentlyInvincible())

if ($stillInvuln -and $expiredInvuln -and ($hcTimer.InvincibilityEndedCount -eq 1)) {
    Write-Host "  [PASS] i-Frame timer ticks down and expires accurately at 0.2s"
} else {
    $failures += "[FAIL] i-Frame timing logic mismatch"
}

# ==============================================================================
# TEST SUITE 5: Shader Mathematical Range & Clamping
# ==============================================================================
$testsRun++
# Shader code fragment: mix(tex_color.rgb, flash_color.rgb, flash_modifier)
$glslMix = {
    param([double]$tex, [double]$flash, [double]$modifier)
    return ($tex * (1.0 - $modifier) + $flash * $modifier)
}

$c1 = & $glslMix 0.2 1.0 0.0
$c2 = & $glslMix 0.2 1.0 1.0
$cOver = & $glslMix 0.2 1.0 2.0
$cNeg = & $glslMix 0.2 1.0 -1.0

if ([Math]::Abs($c1 - 0.2) -lt 0.001 -and [Math]::Abs($c2 - 1.0) -lt 0.001) {
    Write-Host "  [PASS] Hit flash shader nominal mix behavior correct for [0.0, 1.0]"
}

if ($cOver -gt 1.0 -or $cNeg -lt 0.0) {
    $failures += "[MEDIUM FINDING] hit_flash.gdshader uses raw flash_modifier in mix() without clamp(). Out-of-bounds modifier (<0.0 or >1.0) creates negative or blown-out colors ($cNeg, $cOver)."
    Write-Host "  [FAIL MEDIUM FINDING] Shader mix formula lacks clamp(flash_modifier, 0.0, 1.0)"
}

# ==============================================================================
# TEST SUITE 6: EventBus Signal Contract Audit
# ==============================================================================
$testsRun++
$ebContent = Get-Content "scripts/autoloads/event_bus.gd" -Raw
if ($ebContent -notmatch "is_connected") {
    $failures += "[MEDIUM FINDING] EventBus lacks connection guards (is_connected) or safe_connect wrappers. Dynamic callers connecting repeatedly without manual guard will throw ERR_INVALID_PARAMETER."
    Write-Host "  [FAIL MEDIUM FINDING] EventBus lacks is_connected guard helpers"
}

# ==============================================================================
# TEST SUMMARY
# ==============================================================================
Write-Host "=================================================="
Write-Host "  STRESS TEST SUMMARY"
Write-Host "  Total Tests Run: $testsRun"
Write-Host "  Failures / Findings Found: $($failures.Count)"
Write-Host "=================================================="

foreach ($f in $failures) {
    Write-Host "  * $f"
}

if ($failures.Count -gt 0) {
    exit 1
} else {
    exit 0
}
