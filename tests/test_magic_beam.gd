extends SceneTree


class DummyEnemy extends Node2D:
	var is_dead := false
	var damage_received := 0

	func take_damage(amount: int, _attacker_position: Vector2) -> void:
		damage_received += amount


func _init() -> void:
	var first := _add_enemy(Vector2(100, 0))
	var second := _add_enemy(Vector2(220, 5))
	var off_line := _add_enemy(Vector2(180, 60))
	var beam := preload("res://scenes/player/PlayerMagicBeam.tscn").instantiate()
	root.add_child(beam)
	beam.setup(Vector2.ZERO, Vector2.RIGHT, 7, 520.0)
	assert(first.damage_received == 7)
	assert(second.damage_received == 7)
	assert(off_line.damage_received == 0)
	print("Magic beam piercing smoke test passed.")
	quit()


func _add_enemy(position: Vector2) -> DummyEnemy:
	var enemy := DummyEnemy.new()
	enemy.position = position
	enemy.add_to_group("enemy")
	root.add_child(enemy)
	return enemy
