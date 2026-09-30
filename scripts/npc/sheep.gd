extends CharacterBody2D

const IDLE_TEXTURE := preload("res://assets/npc/Sheep/Sheep_Idle.png")

@export var speed := 28.0
@export var waypoint_tolerance := 3.0
@export var waypoints := PackedVector2Array([
	Vector2.ZERO,
	Vector2(72, 0),
	Vector2(72, 52),
	Vector2(0, 52),
])

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var speech_bubble: Label = $SpeechBubble
@onready var speech_timer: Timer = $SpeechTimer
@onready var speech_cooldown: Timer = $SpeechCooldown

var waypoint_index := 0
var fleeing := false
var nearby_player: Node2D
var flee_origin: Vector2


func _ready() -> void:
	assert(not waypoints.is_empty(), "Sheep needs at least one waypoint.")
	for index in waypoints.size():
		waypoints[index] += global_position
	$PlayerDetector.body_entered.connect(_on_player_entered)
	speech_timer.timeout.connect(speech_bubble.hide)
	_add_idle_animation()
	sprite.play(&"idle")
	speech_bubble.hide()


func _physics_process(_delta: float) -> void:
	if fleeing and (not is_instance_valid(nearby_player) or flee_origin.distance_to(nearby_player.global_position) > 70.0):
		fleeing = false
		nearby_player = null
	if not fleeing:
		velocity = Vector2.ZERO
		sprite.play(&"idle")
		return

	var target := waypoints[waypoint_index]
	if global_position.distance_to(target) <= waypoint_tolerance:
		velocity = Vector2.ZERO
		sprite.play(&"idle")
		return

	sprite.play(&"move")
	var direction := global_position.direction_to(target)
	velocity = direction * speed
	sprite.flip_h = velocity.x < 0.0
	move_and_slide()


func _on_player_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	fleeing = true
	nearby_player = body
	flee_origin = global_position
	for index in waypoints.size():
		if waypoints[index].distance_squared_to(body.global_position) > waypoints[waypoint_index].distance_squared_to(body.global_position):
			waypoint_index = index

	if speech_cooldown.is_stopped():
		speech_bubble.text = ["Beee!", "Beeeeee!", "Baa-aa!"].pick_random()
		speech_bubble.show()
		speech_timer.start()
		speech_cooldown.start()


func _add_idle_animation() -> void:
	if sprite.sprite_frames.has_animation(&"idle"):
		return

	sprite.sprite_frames.add_animation(&"idle")
	sprite.sprite_frames.set_animation_speed(&"idle", 6.0)
	for index in 6:
		var frame := AtlasTexture.new()
		frame.atlas = IDLE_TEXTURE
		frame.region = Rect2(index * 128, 0, 128, 128)
		sprite.sprite_frames.add_frame(&"idle", frame)
