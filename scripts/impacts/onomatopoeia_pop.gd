extends Sprite2D
class_name OnomatopoeiaPop
## Onomatopée comic (BOOM, PAF, GRRZZZLL…) qui pop puis disparaît.
##
## Usage (une ligne depuis n'importe où) :
##   OnomatopoeiaPop.spawn(parent, global_pos, "paf")
##   OnomatopoeiaPop.spawn(parent, global_pos, "grrzzzll", 220.0)
##
## Pour ajouter une onomatopée : déposer l'image dans assets/FX/ et
## ajouter une entrée au dictionnaire TEXTURES ci-dessous.

const TEXTURES := {
	"boom": preload("res://assets/FX/boom.png"),
	"paf": preload("res://assets/FX/paf.png"),
	"grrzzzll": preload("res://assets/FX/grrzzzll.png"),
	"shock": preload("res://assets/FX/shock.png"),
	"burn": preload("res://assets/FX/burn.png"),
	"splash": preload("res://assets/FX/splash256.png"),
	"electrocution": preload("res://assets/FX/Electrocution.png"),
}


## Fait apparaître une onomatopée à [param world_pos] dans [param parent].
## [param target_width] = largeur visée en pixels (normalise les résolutions).
## [param speed] > 1.0 = pop plus rapide (pour les events fréquents comme les tirs).
static func spawn(
	parent: Node,
	world_pos: Vector2,
	key: String,
	target_width: float = 150.0,
	speed: float = 1.0
) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	if not TEXTURES.has(key):
		push_warning("OnomatopoeiaPop : clé inconnue '%s'" % key)
		return

	var pop := OnomatopoeiaPop.new()
	pop.texture = TEXTURES[key]
	parent.add_child(pop)
	pop.global_position = world_pos
	pop._animate(target_width, speed)


func _animate(target_width: float, speed: float) -> void:
	z_index = 200   # au-dessus des explosions (z=100) et autres effets
	var tex_w: float = texture.get_width()
	var target_scale: float = target_width / maxf(tex_w, 1.0)
	scale = Vector2(0.02, 0.02)
	rotation = randf_range(-0.18, 0.18)

	var inv := 1.0 / maxf(speed, 0.01)
	var t := create_tween()
	t.set_parallel(true)
	# Pop élastique
	t.tween_property(self, "scale", Vector2(target_scale, target_scale), 0.22 * inv) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Maintien puis fondu
	t.tween_property(self, "modulate:a", 0.0, 0.3 * inv).set_delay(0.25 * inv)
	# Dérive vers le haut
	t.tween_property(self, "position:y", position.y - 20.0, 0.5 * inv) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(queue_free)
