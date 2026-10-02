extends "res://scripts/enemies/enemy.gd"

const BOMB_SCENE := preload("res://scenes/enemies/Water/BombProjectile.tscn")


func attack_player() -> void:
	if is_dead or not is_instance_valid(player):
		return

	var bomb := BOMB_SCENE.instantiate()
	AudioManager.play_sfx(&"bomb_throw", 1.0, -6.0)
	get_tree().current_scene.add_child(bomb)
	bomb.setup(global_position, player.global_position, attack_damage, player)
	play_attack_animation()
	attack_cooldown_left = attack_cooldown
