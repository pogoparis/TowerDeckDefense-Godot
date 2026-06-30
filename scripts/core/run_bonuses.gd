extends Node

var owned_bonuses: Array[BonusData] = []

func add_bonus(bonus: BonusData):
	if bonus == null:
		return
	owned_bonuses.append(bonus)
	refresh_all_towers()

# ── Tours ─────────────────────────────────────────────
func get_total_damage_bonus() -> int:
	var total := 0
	for b in owned_bonuses: total += b.damage_bonus
	return total

func get_total_range_bonus() -> int:
	var total := 0
	for b in owned_bonuses: total += b.range_bonus
	return total

func get_fire_rate_multiplier() -> float:
	var mult := 1.0
	for b in owned_bonuses: mult *= b.fire_rate_mult
	return mult

func get_wet_duration_bonus() -> float:
	var total := 0.0
	for b in owned_bonuses: total += b.wet_duration_bonus
	return total

# ── Réactions ─────────────────────────────────────────
func get_mini_shock_damage_bonus() -> int:
	var total := 0
	for b in owned_bonuses: total += b.mini_shock_damage_bonus
	return total

func get_mini_shock_cooldown_mult() -> float:
	var mult := 1.0
	for b in owned_bonuses: mult *= b.mini_shock_cooldown_mult
	return mult

func get_electrocution_damage_mult() -> float:
	var mult := 1.0
	for b in owned_bonuses: mult *= b.electrocution_damage_mult
	return mult

func get_stun_duration_bonus() -> float:
	var total := 0.0
	for b in owned_bonuses: total += b.stun_duration_bonus
	return total

func get_wet_tick_damage() -> int:
	var total := 0
	for b in owned_bonuses: total += b.wet_tick_damage
	return total

# ── Phénomènes ────────────────────────────────────────
func get_phenomenon_radius_mult() -> float:
	var mult := 1.0
	for b in owned_bonuses: mult *= b.phenomenon_radius_mult
	return mult

func get_phenomenon_duration_bonus() -> float:
	var total := 0.0
	for b in owned_bonuses: total += b.phenomenon_duration_bonus
	return total

func get_consume_cost_reduction() -> int:
	var total := 0
	for b in owned_bonuses: total += b.consume_cost_reduction
	return total

# ── Économie ─────────────────────────────────────────
func get_caps_per_wave() -> int:
	var total := 0
	for b in owned_bonuses: total += b.caps_per_wave
	return total

func get_post_wave_draw_bonus() -> int:
	var total := 0
	for b in owned_bonuses: total += b.post_wave_draw_bonus
	return total

# ── Refresh ───────────────────────────────────────────
func refresh_all_towers():
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower is BaseTower:
			tower.apply_run_bonuses()
