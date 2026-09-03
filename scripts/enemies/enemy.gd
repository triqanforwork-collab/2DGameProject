extends CharacterBody2D

@export var health: int = 3
@export var speed: float = 100.0

@export var attack_damage: int = 1
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 1.0


var player: CharacterBody2D
var attack_cooldown_left: float = 0.0


func _ready() -> void:
	add_to_group("enemy")

	player = get_tree().get_first_node_in_group("player") as CharacterBody2D


func _physics_process(delta: float) -> void:
	if player == null:
		return

	if not is_instance_valid(player):
		return

	if attack_cooldown_left > 0.0:
		attack_cooldown_left -= delta

	var distance := global_position.distance_to(player.global_position)

	if distance > attack_range:
		chase_player()
	else:
		stop_moving()

		if attack_cooldown_left <= 0.0:
			attack_player()


func chase_player() -> void:
	var direction := global_position.direction_to(player.global_position)

	velocity = direction * speed
	move_and_slide()


func stop_moving() -> void:
	velocity = Vector2.ZERO


func attack_player() -> void:
	player.take_damage(attack_damage, global_position)
	attack_cooldown_left = attack_cooldown


func take_damage(damage: int) -> void:
	health -= damage

	print("Enemy HP: ", health)

	if health <= 0:
		die()


func die() -> void:
	print("Enemy died")
	queue_free()
