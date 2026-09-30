extends SceneTree


class DummyEnemy extends Node2D:
	var is_dead := false


func _init() -> void:
	var enemy := DummyEnemy.new()
	enemy.position = Vector2(100, 100)
	enemy.add_to_group("enemy")
	root.add_child(enemy)

	var projectile := preload("res://scenes/player/PlayerAreaAttackProjectile.tscn").instantiate()
	root.add_child(projectile)
	projectile.setup(Vector2.ZERO, Vector2.RIGHT, 10, 100.0, 500.0)
	projectile._physics_process(0.1)
	assert(projectile.target == enemy)
	assert(projectile.global_position.y > 0.0, "Area Attack did not home toward its target.")
	print("Area Attack homing smoke test passed.")
	quit()
