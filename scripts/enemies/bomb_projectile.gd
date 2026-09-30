extends Node2D

enum Phase { FLYING, FUSE, EXPLODING }

@export var flight_duration := 0.7
@export var fuse_duration := 2.0
@export var arc_height := 70.0
@export var explosion_radius := 60.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var phase := Phase.FLYING
var phase_time := 0.0
var start_position := Vector2.ZERO
var landing_position := Vector2.ZERO
var damage := 1
var target: Node2D
var configured := false


func setup(from: Vector2, to: Vector2, attack_damage: int, player: Node2D) -> void:
	start_position = from
	landing_position = to
	damage = maxi(attack_damage, 1)
	target = player
	global_position = from
	configured = true


func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	_set_phase(Phase.FLYING)


func _process(delta: float) -> void:
	if not configured:
		return

	phase_time += delta
	if phase == Phase.FLYING:
		var progress := minf(phase_time / flight_duration, 1.0)
		global_position = start_position.lerp(landing_position, progress)
		sprite.position.y = -4.0 * arc_height * progress * (1.0 - progress)
		if progress >= 1.0:
			_set_phase(Phase.FUSE)
	elif phase == Phase.FUSE and phase_time >= fuse_duration:
		_explode()

	queue_redraw()


func _set_phase(next_phase: Phase) -> void:
	phase = next_phase
	phase_time = 0.0
	sprite.position = Vector2.ZERO
	match phase:
		Phase.FLYING: sprite.play(&"spinning")
		Phase.FUSE: sprite.play(&"fuse")
		Phase.EXPLODING: sprite.play(&"explosion")


func _explode() -> void:
	_set_phase(Phase.EXPLODING)
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= explosion_radius:
		target.take_damage(damage, global_position)


func _on_animation_finished() -> void:
	if phase == Phase.EXPLODING:
		queue_free()


func _draw() -> void:
	if phase == Phase.EXPLODING:
		return

	var center := landing_position - global_position
	var pulse := 0.75 + sin(phase_time * 10.0) * 0.25 if phase == Phase.FUSE else 0.55
	draw_circle(center, explosion_radius, Color(1.0, 0.15, 0.05, 0.12 * pulse))
	draw_arc(center, explosion_radius, 0.0, TAU, 48, Color(1.0, 0.2, 0.05, pulse), 3.0)
