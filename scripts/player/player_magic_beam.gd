extends Node2D

@export var duration := 0.16
@export var beam_width := 10.0
@export var hit_radius := 20.0
@export_range(1.0, 90.0, 1.0) var auto_aim_half_angle := 45.0

var beam_end := Vector2.ZERO
var locked_target_position := Vector2.ZERO


func setup(start_position: Vector2, facing_direction: Vector2, damage: int, max_range: float) -> void:
	global_position = start_position
	var direction := _get_beam_direction(facing_direction.normalized(), max_range)
	var end_position := _get_wall_limited_end(start_position, direction, max_range)
	beam_end = to_local(end_position)
	_damage_enemies_on_beam(start_position, end_position, maxi(damage, 1))
	queue_redraw()

	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, duration)
	fade.finished.connect(queue_free)


func _get_beam_direction(facing_direction: Vector2, max_range: float) -> Vector2:
	var best_target: Node2D
	var best_distance_squared := max_range * max_range
	var minimum_dot := cos(deg_to_rad(auto_aim_half_angle))

	for candidate in get_tree().get_nodes_in_group("enemy"):
		var enemy := candidate as Node2D
		if enemy == null or bool(enemy.get("is_dead")):
			continue

		var offset := enemy.global_position - global_position
		var distance_squared := offset.length_squared()
		if distance_squared > best_distance_squared or distance_squared <= 0.0:
			continue
		if facing_direction.dot(offset.normalized()) < minimum_dot:
			continue
		if not _has_clear_path(global_position, enemy.global_position):
			continue

		best_target = enemy
		best_distance_squared = distance_squared

	if best_target == null:
		return facing_direction

	locked_target_position = to_local(best_target.global_position)
	return global_position.direction_to(best_target.global_position)


func _get_wall_limited_end(start_position: Vector2, direction: Vector2, max_range: float) -> Vector2:
	var intended_end := start_position + direction * maxf(max_range, 1.0)
	var query := PhysicsRayQueryParameters2D.create(start_position, intended_end, 1)
	query.collide_with_areas = false
	var collision := get_world_2d().direct_space_state.intersect_ray(query)
	return collision.get("position", intended_end) as Vector2


func _has_clear_path(start_position: Vector2, end_position: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(start_position, end_position, 1)
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _damage_enemies_on_beam(start_position: Vector2, end_position: Vector2, damage: int) -> void:
	for candidate in get_tree().get_nodes_in_group("enemy"):
		var enemy := candidate as Node2D
		if enemy == null or bool(enemy.get("is_dead")) or not enemy.has_method("take_damage"):
			continue

		var closest_point := Geometry2D.get_closest_point_to_segment(enemy.global_position, start_position, end_position)
		if enemy.global_position.distance_to(closest_point) <= hit_radius:
			enemy.take_damage(damage, start_position)


func _draw() -> void:
	draw_line(Vector2.ZERO, beam_end, Color(0.15, 0.95, 0.82, 0.5), beam_width + 12.0, true)
	draw_line(Vector2.ZERO, beam_end, Color(0.2, 0.9, 0.78, 1.0), beam_width, true)
	draw_line(Vector2.ZERO, beam_end, Color(0.92, 1.0, 0.8, 1.0), 2.5, true)
	if locked_target_position != Vector2.ZERO:
		draw_arc(locked_target_position, 13.0, 0.0, TAU, 20, Color(0.92, 1.0, 0.55, 0.95), 2.0, true)
