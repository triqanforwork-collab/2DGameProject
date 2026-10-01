extends Node2D

const SHEET_EFFECT := preload("res://scripts/effects/sprite_sheet_effect.gd")

var radius := 50.0
var delay := 0.8
var damage := 1
var target: Node2D
var color := Color.ORANGE
var duration := 0.0
var drift := Vector2.ZERO
var stun_duration := 0.0
var elapsed := 0.0
var active := false
var damage_cooldown := 0.0
var rock_texture: Texture2D
var repeat_damage := true
var effect_data := []
var warning_fill_alpha := 0.12
var warning_outline_alpha := 1.0
var active_fill_alpha := 0.28
var active_outline_alpha := 1.0


func setup(center: Vector2, area_radius: float, warning_delay: float, attack_damage: int, player: Node2D, tint: Color, active_duration := 0.0, movement := Vector2.ZERO, stun := 0.0, texture: Texture2D = null) -> void:
	global_position = center
	radius = area_radius
	delay = warning_delay
	damage = attack_damage
	target = player
	color = tint
	duration = active_duration
	drift = movement
	stun_duration = stun
	rock_texture = texture
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	if not active and elapsed >= delay:
		active = true
		elapsed = 0.0
		_hit_target()
		_start_effect()
		queue_redraw()
	elif active:
		global_position += drift * delta
		damage_cooldown -= delta
		if repeat_damage and duration > 0.0 and damage_cooldown <= 0.0:
			_hit_target()
		if duration <= 0.0 or elapsed >= duration:
			queue_free()


func set_repeat_damage(enabled: bool) -> void:
	repeat_damage = enabled


func set_circle_opacity(warning_fill: float, warning_outline: float, active_fill: float, active_outline: float) -> void:
	warning_fill_alpha = warning_fill
	warning_outline_alpha = warning_outline
	active_fill_alpha = active_fill
	active_outline_alpha = active_outline
	queue_redraw()


func set_effect(sheet: Texture2D, frame_size: Vector2i, frame_count: int, fps: float, loop := false, visual_scale := Vector2.ONE, tint := Color.WHITE) -> void:
	effect_data = [sheet, frame_size, frame_count, fps, loop, visual_scale, tint]


func _start_effect() -> void:
	if effect_data.is_empty():
		return
	var effect: Sprite2D = SHEET_EFFECT.new()
	add_child(effect)
	effect.setup(effect_data[0], effect_data[1], effect_data[2], effect_data[3], effect_data[4], effect_data[5], effect_data[6])
	queue_redraw()


func _hit_target() -> void:
	damage_cooldown = 0.65
	if not is_instance_valid(target) or global_position.distance_to(target.global_position) > radius:
		return
	target.take_damage(damage, global_position)
	if stun_duration > 0.0 and target.has_method("apply_stun"):
		target.apply_stun(stun_duration)


func _draw() -> void:
	var pulse := 0.75 + sin(elapsed * 10.0) * 0.2
	if not active:
		draw_circle(Vector2.ZERO, radius, Color(color, warning_fill_alpha))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, pulse * warning_outline_alpha), 3.0)
		return
	draw_circle(Vector2.ZERO, radius, Color(color, active_fill_alpha))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, active_outline_alpha), 4.0)
	if rock_texture != null:
		draw_texture_rect(rock_texture, Rect2(-32, -48, 64, 64), false)
