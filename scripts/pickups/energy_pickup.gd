extends Area2D

@export_range(1, 30, 1) var energy_value := 1
@export var magnet_radius := 96.0
@export var magnet_speed := 220.0
@export var pickup_delay := 0.18
@export var launch_duration := 0.35

@onready var visuals: Node2D = $Visuals
@onready var orb: Sprite2D = $Visuals/Orb
@onready var aura_particles: GPUParticles2D = $Visuals/AuraParticles
@onready var collect_particles: GPUParticles2D = $CollectParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var player: CharacterBody2D
var collected := false
var pickup_delay_left := 0.0
var launch_time_left := 0.0
var launch_velocity := Vector2.ZERO
var bob_time := 0.0
var base_visual_scale := 1.0


func _ready() -> void:
	add_to_group("energy_pickup")
	body_entered.connect(_on_body_entered)
	monitoring = false
	pickup_delay_left = pickup_delay
	launch_time_left = launch_duration
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	base_visual_scale = 1.15 + minf(float(energy_value - 1) * 0.06, 0.24)
	_configure_visuals()


func _process(delta: float) -> void:
	if collected:
		return

	bob_time += delta
	var pulse := base_visual_scale * (1.0 + sin(bob_time * 4.0) * 0.06)
	visuals.scale = Vector2.ONE * pulse
	visuals.position.y = sin(bob_time * 3.0) * 2.0


func _physics_process(delta: float) -> void:
	if collected:
		return

	if pickup_delay_left > 0.0:
		pickup_delay_left -= delta
		if pickup_delay_left <= 0.0:
			set_deferred("monitoring", true)

	if launch_time_left > 0.0:
		launch_time_left -= delta
		global_position += launch_velocity * delta
		launch_velocity = launch_velocity.move_toward(Vector2.ZERO, 260.0 * delta)
		return

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player == null:
			return

	if global_position.distance_to(player.global_position) <= magnet_radius:
		global_position = global_position.move_toward(player.global_position, magnet_speed * delta)


func set_energy_value(value: int) -> void:
	energy_value = maxi(value, 1)


func launch(direction: Vector2, speed: float) -> void:
	launch_velocity = direction.normalized() * speed
	launch_time_left = launch_duration


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return

	collected = true
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	remove_from_group("boss_energy_pickup")
	EnergyManager.add_energy(energy_value)
	AudioManager.play_sfx(&"energy_pickup", randf_range(0.95, 1.12), -5.0)

	visuals.visible = false
	aura_particles.emitting = false
	collect_particles.restart()
	collect_particles.emitting = true

	await get_tree().create_timer(0.55, true).timeout
	queue_free()


func _configure_visuals() -> void:
	var orb_texture := _create_glow_texture(24, 24)
	orb.texture = orb_texture
	orb.modulate = Color(0.35, 0.95, 1.0, 1.0)

	var particle_texture := _create_glow_texture(5, 5)
	aura_particles.texture = particle_texture
	aura_particles.process_material = _create_aura_material()
	aura_particles.preprocess = 1.2
	aura_particles.emitting = true

	collect_particles.texture = particle_texture
	collect_particles.process_material = _create_collect_material()


func _create_glow_texture(width: int, height: int) -> GradientTexture2D:
	var alpha_gradient := Gradient.new()
	alpha_gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	alpha_gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.8),
		Color(1.0, 1.0, 1.0, 0.0)
	])

	var texture := GradientTexture2D.new()
	texture.width = width
	texture.height = height
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = alpha_gradient
	return texture


func _create_aura_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 9.0
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 180.0
	material.initial_velocity_min = 7.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3(0.0, -4.0, 0.0)
	material.scale_min = 0.5
	material.scale_max = 1.1
	material.color_ramp = _create_particle_ramp(
		Color(0.75, 1.0, 0.55, 1.0),
		Color(0.2, 0.9, 1.0, 0.0)
	)
	return material


func _create_collect_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 3.0
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 180.0
	material.initial_velocity_min = 35.0
	material.initial_velocity_max = 65.0
	material.gravity = Vector3(0.0, 55.0, 0.0)
	material.scale_min = 0.7
	material.scale_max = 1.4
	material.color_ramp = _create_particle_ramp(
		Color(1.0, 1.0, 0.65, 1.0),
		Color(0.25, 0.95, 1.0, 0.0)
	)
	return material


func _create_particle_ramp(start_color: Color, end_color: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
	gradient.colors = PackedColorArray([
		Color.WHITE,
		start_color,
		end_color
	])

	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	return ramp
