extends BaseProjectile
class_name FireProjectile

@onready var glow_sprite: Sprite2D = $GlowSprite

func _process(delta):

	super._process(delta)

	if glow_sprite == null:
		return

	glow_sprite.visible = (
		source_tower != null
		and source_tower.laser_guide_active
	)

	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.15

	glow_sprite.scale = Vector2.ONE * pulse * 1.4


func on_hit(target):

	var final_damage = damage

	if (
		source_tower != null
		and source_tower.laser_guide_active
		and target.has_status(SynergyIds.VEGA_MARK)
	):
		final_damage = int(final_damage * 1.5)

	target.take_damage(final_damage)

	spawn_tower_phenomenon(target)
