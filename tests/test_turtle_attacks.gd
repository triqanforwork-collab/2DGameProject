extends SceneTree


class DummyPlayer extends CharacterBody2D:
	var damage_received := 0

	func take_damage(amount: int, _source: Vector2) -> void:
		damage_received += amount


func _init() -> void:
	var player := DummyPlayer.new()
	player.position = Vector2(100.0, 0.0)
	player.add_to_group("player")
	root.add_child(player)
	var turtle := preload("res://scenes/bosses/Water/Turtle.tscn").instantiate()
	root.add_child(turtle)
	turtle.player = player
	assert(turtle._choose_attack() == &"dash")
	player.position = Vector2(150.0, 0.0)
	assert(turtle._choose_attack() == &"laser")
	player.position = Vector2(220.0, 0.0)
	assert(turtle._choose_attack() == &"volley")
	var projectile := preload("res://scenes/bosses/Water/TurtleWaterProjectile.tscn").instantiate()
	root.add_child(projectile)
	projectile.setup(Vector2.ZERO, Vector2.RIGHT, 2)
	projectile._on_body_entered(player)
	assert(player.damage_received == 2)
	print("Turtle attack smoke test passed.")
	quit()
