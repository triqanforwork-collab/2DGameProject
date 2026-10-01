extends "res://scripts/bosses/boss.gd"

const PROJECTILE := preload("res://scripts/bosses/boss_projectile.gd")
const HAZARD := preload("res://scripts/bosses/boss_area_hazard.gd")
const SHEET_EFFECT := preload("res://scripts/effects/sprite_sheet_effect.gd")

var special_active := false
var last_attack := &""
var telegraph_direction := Vector2.ZERO
var telegraph_color := Color.ORANGE
var telegraph_length := 260.0
var telegraph_visible := false


func _physics_process(delta: float) -> void:
	if not special_active:
		super(delta)
		return
	stop_moving()
	if boss_health_bar != null:
		boss_health_bar.visible = has_detected_player and not is_dead


func can_special_attack() -> bool:
	return is_inside_tree() and not is_dead and is_instance_valid(player)


func finish_special(recovery := 0.8) -> void:
	if not can_special_attack():
		return
	play_animation(idle_animation)
	await get_tree().create_timer(recovery).timeout
	if not can_special_attack():
		return
	special_active = false
	attack_cooldown_left = attack_cooldown


func show_line_telegraph(direction: Vector2, duration: float, color := Color.ORANGE, length := 260.0) -> void:
	telegraph_direction = direction
	telegraph_color = color
	telegraph_length = length
	telegraph_visible = true
	queue_redraw()
	await get_tree().create_timer(duration).timeout
	telegraph_visible = false
	queue_redraw()


func spawn_projectile(direction: Vector2, projectile_speed: float, damage: int, color: Color, radius := 12.0, lifetime := 3.0, splits := 0) -> Node2D:
	var projectile := PROJECTILE.new()
	get_tree().current_scene.add_child(projectile)
	projectile.setup(global_position, direction, projectile_speed, damage, player, color, radius, lifetime, splits)
	return projectile


func spawn_hazard(position: Vector2, radius: float, delay: float, damage: int, color: Color, duration := 0.0, drift := Vector2.ZERO, stun := 0.0, texture: Texture2D = null) -> Node2D:
	var hazard := HAZARD.new()
	get_tree().current_scene.add_child(hazard)
	hazard.setup(position, radius, delay, damage, player, color, duration, drift, stun, texture)
	return hazard


func spawn_sheet_effect(position: Vector2, sheet: Texture2D, frame_size: Vector2i, frame_count: int, fps: float, loop := false, visual_scale := Vector2.ONE, tint := Color.WHITE, parent: Node = null) -> Sprite2D:
	var effect: Sprite2D = SHEET_EFFECT.new()
	(parent if parent != null else get_tree().current_scene).add_child(effect)
	effect.global_position = position
	effect.setup(sheet, frame_size, frame_count, fps, loop, visual_scale, tint)
	return effect


func _draw() -> void:
	if telegraph_visible:
		draw_line(Vector2.ZERO, telegraph_direction * telegraph_length, Color(telegraph_color, 0.2), 18.0)
		draw_line(Vector2.ZERO, telegraph_direction * telegraph_length, telegraph_color, 3.0)
