extends Node
class_name FloatingTextService

const FLOATING_TEXT_SCENE = preload(
	"res://scenes/ui/floating_text.tscn"
)

static func spawn(
	parent: Node,
	world_position: Vector2,
	text: String,
	color: Color = Color.WHITE,
	text_scale: float = 1.2
):

	var floating_text = (
		FLOATING_TEXT_SCENE.instantiate()
	)

	parent.add_child(
		floating_text
	)

	floating_text.global_position = (
		world_position
	)

	floating_text.setup(
		text,
		color,
		text_scale
	)
