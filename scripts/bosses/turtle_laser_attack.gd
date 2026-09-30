extends Node2D

signal finished

var target: Node2D
var damage := 1
var elapsed := 0.0
var damage_cooldown := 0.0
var active := false
var rotation_angle := 0.0


func setup(origin: Vector2, player: Node2D, attack_damage: int) -> void:
	global_position = origin
	target = player
	damage = maxi(attack_damage, 1)


func _process(delta: float) -> void:
	elapsed += delta
	damage_cooldown = maxf(damage_cooldown - delta, 0.0)
	if not active and elapsed >= 1.0:
		active = true
		elapsed = 0.0
	elif active:
		rotation_angle += deg_to_rad(90.0) * delta
		_apply_damage()
		if elapsed >= 2.5:
			finished.emit()
			queue_free()
	queue_redraw()


func _apply_damage() -> void:
	if damage_cooldown > 0.0 or not is_instance_valid(target):
		return
	for index in 3:
		var end := Vector2.RIGHT.rotated(rotation_angle + TAU * index / 3.0) * 280.0
		if _distance_to_segment(target.global_position - global_position, Vector2.ZERO, end) <= 13.0:
			target.take_damage(damage, global_position)
			damage_cooldown = 0.7
			return


func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var line := end - start
	var progress := clampf((point - start).dot(line) / line.length_squared(), 0.0, 1.0)
	return point.distance_to(start + line * progress)


func _draw() -> void:
	var color := Color(0.1, 0.85, 1.0, 0.9) if active else Color(0.1, 0.85, 1.0, 0.25)
	var width := 10.0 if active else 4.0
	for index in 3:
		var end := Vector2.RIGHT.rotated(rotation_angle + TAU * index / 3.0) * 280.0
		draw_line(Vector2.ZERO, end, color, width)
		if active:
			draw_line(Vector2.ZERO, end, Color.WHITE, 2.0)
