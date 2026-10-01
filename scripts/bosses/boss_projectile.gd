extends Node2D

const SHEET_EFFECT := preload("res://scripts/effects/sprite_sheet_effect.gd")

var direction := Vector2.RIGHT
var speed := 180.0
var damage := 1
var target: Node2D
var color := Color.CYAN
var radius := 10.0
var lifetime := 3.0
var splits_left := 0
var hit := false
var custom_visual := false
var visual_data := []


func setup(start: Vector2, travel_direction: Vector2, travel_speed: float, attack_damage: int, player: Node2D, tint: Color, hit_radius := 10.0, life := 3.0, splits := 0) -> void:
	global_position = start
	direction = travel_direction.normalized()
	speed = travel_speed
	damage = attack_damage
	target = player
	color = tint
	radius = hit_radius
	lifetime = life
	splits_left = splits
	queue_redraw()


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	rotation = direction.angle()
	if not hit and is_instance_valid(target) and global_position.distance_to(target.global_position) <= radius + 14.0:
		target.take_damage(damage, global_position)
		hit = true
		queue_free()
	elif lifetime <= 0.0:
		_split()


func _split() -> void:
	if splits_left > 0 and is_inside_tree():
		for angle in [-22.0, 22.0]:
			var child: Node2D = get_script().new()
			get_tree().current_scene.add_child(child)
			child.setup(global_position, direction.rotated(deg_to_rad(angle)), speed * 0.85, maxi(1, damage - 1), target, color, radius * 0.8, 1.0, splits_left - 1)
			if not visual_data.is_empty():
				child.set_visual(visual_data[0], visual_data[1], visual_data[2], visual_data[3], visual_data[4] * 0.8, visual_data[5])
	queue_free()


func set_visual(sheet: Texture2D, frame_size: Vector2i, frame_count: int, fps: float, visual_scale := Vector2.ONE, tint := Color.WHITE) -> void:
	custom_visual = true
	visual_data = [sheet, frame_size, frame_count, fps, visual_scale, tint]
	var effect: Sprite2D = SHEET_EFFECT.new()
	add_child(effect)
	effect.setup(sheet, frame_size, frame_count, fps, true, visual_scale, tint)
	queue_redraw()


func _draw() -> void:
	if custom_visual:
		return
	draw_circle(Vector2.ZERO, radius * 1.8, Color(color, 0.16))
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.45, Color.WHITE)
