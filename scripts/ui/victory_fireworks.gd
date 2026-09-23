extends Control

@export_range(1.0, 10.0, 0.5) var celebration_duration := 4.5
@export_range(0.2, 2.0, 0.05) var spawn_interval := 0.55
@export_range(1, 6, 1) var max_active_bursts := 3

@onready var burst_container: Node2D = $BurstContainer
@onready var spawn_timer: Timer = $SpawnTimer

var is_playing := false
var elapsed_time := 0.0
var particle_texture: GradientTexture2D
var random := RandomNumberGenerator.new()

const BURST_COLORS := [
	Color("ffd166"),
	Color("58e1ff"),
	Color("ff6b9f"),
	Color("7dff8a"),
	Color("c7a6ff")
]


func _ready() -> void:
	visible = false
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_burst)
	particle_texture = _create_particle_texture()
	random.randomize()


func _process(delta: float) -> void:
	if not is_playing:
		return

	elapsed_time += delta
	if elapsed_time >= celebration_duration:
		_stop_spawning()


func play() -> void:
	_clear_bursts()
	is_playing = true
	elapsed_time = 0.0
	visible = true
	_spawn_burst()
	spawn_timer.start()


func stop() -> void:
	_stop_spawning()
	_clear_bursts()
	visible = false


func _stop_spawning() -> void:
	is_playing = false
	spawn_timer.stop()
	_refresh_visibility.call_deferred()


func _spawn_burst() -> void:
	if not is_playing or burst_container.get_child_count() >= max_active_bursts:
		return

	var burst := CPUParticles2D.new()
	burst.name = "FireworkBurst"
	burst.process_mode = Node.PROCESS_MODE_ALWAYS
	burst.position = _get_burst_position()
	burst.texture = particle_texture
	burst.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	burst.amount = 40
	burst.lifetime = 1.8
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.randomness = 0.25
	burst.direction = Vector2.UP
	burst.particle_flag_align_y = true
	burst.spread = 180.0
	burst.initial_velocity_min = 110.0
	burst.initial_velocity_max = 175.0
	burst.gravity = Vector2(0.0, 85.0)
	burst.damping_min = 12.0
	burst.damping_max = 20.0
	burst.scale_amount_min = 0.8
	burst.scale_amount_max = 1.5
	burst.scale_amount_curve = _create_scale_curve()
	burst.color_ramp = _create_color_ramp(BURST_COLORS[random.randi_range(0, BURST_COLORS.size() - 1)])
	burst.finished.connect(_on_burst_finished.bind(burst), CONNECT_ONE_SHOT)
	burst_container.add_child(burst)
	burst.emitting = true


func _get_burst_position() -> Vector2:
	var display_size := size
	if display_size.x <= 0.0 or display_size.y <= 0.0:
		display_size = get_viewport_rect().size

	var x_min := display_size.x * 0.18
	var x_max := display_size.x * 0.36
	if random.randf() > 0.5:
		x_min = display_size.x * 0.64
		x_max = display_size.x * 0.82

	return Vector2(
		random.randf_range(x_min, x_max),
		random.randf_range(display_size.y * 0.18, display_size.y * 0.38)
	)


func _create_particle_texture() -> GradientTexture2D:
	var alpha_gradient := Gradient.new()
	alpha_gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	alpha_gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.9),
		Color(1.0, 1.0, 1.0, 0.0)
	])

	var texture := GradientTexture2D.new()
	texture.width = 4
	texture.height = 10
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = alpha_gradient
	return texture


func _create_color_ramp(burst_color: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.18, 0.75, 1.0])
	ramp.colors = PackedColorArray([
		Color.WHITE,
		burst_color,
		burst_color,
		Color(burst_color.r, burst_color.g, burst_color.b, 0.0)
	])
	return ramp


func _create_scale_curve() -> Curve:
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.72, 0.7))
	scale_curve.add_point(Vector2(1.0, 0.0))
	return scale_curve


func _on_burst_finished(burst: CPUParticles2D) -> void:
	if is_instance_valid(burst):
		burst.tree_exited.connect(_refresh_visibility, CONNECT_ONE_SHOT)
		burst.queue_free()


func _refresh_visibility() -> void:
	if not is_playing and burst_container.get_child_count() == 0:
		visible = false


func _clear_bursts() -> void:
	for burst in burst_container.get_children():
		burst.queue_free()