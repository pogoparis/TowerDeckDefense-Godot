extends EnemyBase
class_name TankMob

enum State { WALK, ROLL, ROLL_END, ROLL_ENRAGED }

const ROLL_SPEED_MULT   := 2.5
const ENRAGE_HP_RATIO   := 0.5
const SPIN_SPEED        := 6.0
const ROLL_MIN_INTERVAL := 4.0
const ROLL_MAX_INTERVAL := 8.0
const ROLL_MIN_DURATION := 1.5
const ROLL_MAX_DURATION := 3.0
const ROLL_END_DURATION := 0.4

var _state: State = State.WALK
var _base_speed: float = 0.0
var _timer: float = 0.0
var _enraged: bool = false

@onready var _anim: AnimatedSprite2D = $VisualRoot/AnimatedSprite2D

func _ready() -> void:
	super()
	_base_speed = speed
	_schedule_next_roll()
	_anim.frame_changed.connect(_on_frame_changed)

func _process(delta: float) -> void:
	super(delta)
	_update_enrage()
	_update_timer(delta)
	_update_visual(delta)

func _update_enrage() -> void:
	if _enraged:
		return
	if float(hp) / float(max_hp) <= ENRAGE_HP_RATIO:
		_enraged = true
		_enter_state(State.ROLL_ENRAGED)

func _update_timer(delta: float) -> void:
	if _state == State.ROLL_ENRAGED:
		return
	_timer -= delta
	if _timer <= 0.0:
		match _state:
			State.WALK:
				_enter_state(State.ROLL)
			State.ROLL:
				_enter_state(State.ROLL_END)
			State.ROLL_END:
				_enter_state(State.WALK)

func _update_visual(delta: float) -> void:
	if not _anim:
		return

	var pf := get_parent()
	var dir_x := 0.0
	if pf is PathFollow2D:
		dir_x = (pf as PathFollow2D).transform.x.x

	match _state:
		State.WALK:
			_anim.rotation = lerp_angle(_anim.rotation, 0.0, delta * 8.0)
		State.ROLL, State.ROLL_ENRAGED:
			if abs(dir_x) > 0.1:
				_anim.flip_h = dir_x > 0.0  # roll par défaut = gauche
			# Toujours sens horaire (rotation positive en Godot 2D)
			_anim.rotation += SPIN_SPEED * delta
		State.ROLL_END:
			_anim.rotation = lerp_angle(_anim.rotation, 0.0, delta * 12.0)
			if abs(dir_x) > 0.1:
				_anim.flip_h = dir_x < 0.0  # tank4-1 regarde droite, flip si va à gauche

func _on_frame_changed() -> void:
	pass

func _schedule_next_roll() -> void:
	_timer = randf_range(ROLL_MIN_INTERVAL, ROLL_MAX_INTERVAL)

func _enter_state(new_state: State) -> void:
	_state = new_state
	match new_state:
		State.WALK:
			speed = _base_speed
			_anim.play("walk")
			_schedule_next_roll()
		State.ROLL:
			speed = _base_speed * ROLL_SPEED_MULT
			_anim.play("roll")
			_timer = randf_range(ROLL_MIN_DURATION, ROLL_MAX_DURATION)
		State.ROLL_END:
			speed = _base_speed
			_anim.flip_h = true  # tank4-1 flippé
			_anim.play("roll_end")
			_timer = ROLL_END_DURATION
		State.ROLL_ENRAGED:
			speed = _base_speed * ROLL_SPEED_MULT
			_anim.play("roll")
