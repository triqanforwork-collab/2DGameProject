extends SceneTree

class DummyPlayer extends Node2D:
	var damage_taken := 0

	func take_damage(amount: int, _source_position := Vector2.ZERO) -> void:
		damage_taken += amount


func _init() -> void:
	call_deferred(&"run_test")


func run_test() -> void:
	var player := DummyPlayer.new()
	player.position = Vector2(40, 0)
	root.add_child(player)

	var bomb = load("res://scenes/enemies/Water/BombProjectile.tscn").instantiate()
	bomb.flight_duration = 0.05
	bomb.fuse_duration = 0.05
	root.add_child(bomb)
	bomb.setup(Vector2.ZERO, player.position, 7, player)

	await create_timer(0.02).timeout
	assert(bomb.sprite.animation == &"spinning")
	await create_timer(0.05).timeout
	assert(bomb.sprite.animation == &"fuse")
	await create_timer(0.06).timeout
	assert(bomb.sprite.animation == &"explosion")
	assert(player.damage_taken == 7)

	print("Bomb projectile smoke test passed.")
	quit()
