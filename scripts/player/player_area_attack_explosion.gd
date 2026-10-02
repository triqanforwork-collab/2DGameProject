extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var damage := 1
var damage_applied := false


func _ready() -> void:
	AudioManager.play_sfx(&"ultimate_explosion")
	animated_sprite.animation_finished.connect(queue_free)
	animated_sprite.play(&"explode")
	_apply_damage.call_deferred()


func setup(attack_damage: int) -> void:
	damage = maxi(attack_damage, 1)


func _apply_damage() -> void:
	await get_tree().physics_frame
	if damage_applied or not is_inside_tree():
		return

	damage_applied = true
	var damaged_enemies: Array[Node] = []
	for area in get_overlapping_areas():
		if not area.is_in_group("enemy_hurtbox"):
			continue

		var enemy := area.get_parent()
		if enemy == null or enemy in damaged_enemies:
			continue

		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, global_position)
			damaged_enemies.append(enemy)
