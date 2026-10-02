extends Area2D

@export var speed := 220.0
@export var lifetime := 2.2

var direction := Vector2.RIGHT
var damage := 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func setup(start: Vector2, travel_direction: Vector2, attack_damage: int) -> void:
	global_position = start
	direction = travel_direction.normalized()
	damage = maxi(attack_damage, 1)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	AudioManager.play_sfx(&"water_impact", randf_range(0.95, 1.08), -3.0)
	if body.is_in_group("player"):
		body.take_damage(damage, global_position)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.0, 0.55, 1.0, 0.08))
	draw_circle(Vector2.ZERO, 14.0, Color(0.0, 0.75, 1.0, 0.16))
	draw_circle(Vector2.ZERO, 9.0, Color(0.0, 0.9, 1.0, 0.75))
	draw_circle(Vector2.ZERO, 5.0, Color(0.75, 1.0, 1.0, 1.0))
