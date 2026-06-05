extends CharacterBody2D

@export var hp := 30

var _paralyze_timer: float = 0.0
var _base_speed: float = 0.0
var _path_follow: PathFollow2D = null


func _ready() -> void:
	_path_follow = get_parent() as PathFollow2D
	if _path_follow:
		_base_speed = _path_follow.speed


func _process(delta: float) -> void:
	if _paralyze_timer > 0.0:
		_paralyze_timer -= delta
		if _path_follow:
			_path_follow.speed = 0.0
		modulate = Color(0.5, 0.85, 1.0)
	elif _path_follow and _path_follow.speed == 0.0:
		_path_follow.speed = _base_speed
		modulate = Color(1, 1, 1, 1)


func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		queue_free()


func apply_paralyze(duration: float) -> void:
	_paralyze_timer = maxf(_paralyze_timer, duration)
