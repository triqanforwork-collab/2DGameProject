class_name BossSpawnEffect
extends Node2D

signal reveal_requested
signal finished

@export var duration := 1.15
@export var reveal_time := 0.62

@onready var barrier_sprite: Sprite2D = $BarrierSprite

var elapsed := 0.0
var reveal_emitted := false


func _ready() -> void:
	visible = false
	set_process(false)


func play() -> void:
	elapsed = 0.0
	reveal_emitted = false
	barrier_sprite.frame = 0
	barrier_sprite.scale = Vector2.ONE * 1.6
	visible = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	barrier_sprite.frame = mini(int(progress * barrier_sprite.hframes), barrier_sprite.hframes - 1)
	barrier_sprite.scale = Vector2.ONE * lerpf(1.6, 2.45, sin(progress * PI))
	queue_redraw()

	if not reveal_emitted and elapsed >= reveal_time:
		reveal_emitted = true
		reveal_requested.emit()

	if elapsed >= duration:
		set_process(false)
		finished.emit()
		queue_free()


func _draw() -> void:
	if not visible:
		return

	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var ring_alpha := sin(progress * PI)
	var outer_radius := lerpf(20.0, 74.0, progress)
	var inner_radius := lerpf(10.0, 48.0, progress)
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 64, Color(0.78, 0.35, 1.0, ring_alpha), 3.0, true)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 48, Color(1.0, 0.78, 0.35, ring_alpha * 0.8), 2.0, true)
