extends CharacterBody2D

const IDLE_TEXTURES := {
	"axe": preload("res://assets/npc/Pawn/Pawn_Idle Axe.png"),
	"pickaxe": preload("res://assets/npc/Pawn/Pawn_Idle Pickaxe.png"),
	"gold": preload("res://assets/npc/Pawn/Pawn_Idle Gold.png"),
}
const GOLD_RUN_TEXTURE := preload("res://assets/npc/Pawn/Pawn_Run Gold.png")

@export_enum("axe", "pickaxe", "gold") var work_animation := "axe"
@export var flee_offset := Vector2(-90, 0)
@export var run_speed := 75.0
@export var speech_text := "I'm sorry!"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var return_delay: Timer = $ReturnDelay
@onready var speech_bubble: Label = $SpeechBubble
@onready var speech_timer: Timer = $SpeechTimer
@onready var speech_cooldown: Timer = $SpeechCooldown

enum State { WORK, FLEE, WAIT, RETURN }

var state := State.WORK
var home_position: Vector2
var safe_position: Vector2
var player_near := false
var nearby_player: Node2D


func _ready() -> void:
	home_position = global_position
	safe_position = home_position + flee_offset
	$PlayerDetector.body_entered.connect(_on_player_entered)
	return_delay.timeout.connect(_return_to_work)
	speech_timer.timeout.connect(speech_bubble.hide)
	_add_idle_animation()
	_add_gold_run_animation()
	sprite.play(_standing_animation())
	speech_bubble.text = speech_text
	speech_bubble.hide()


func _physics_process(_delta: float) -> void:
	if player_near and (not is_instance_valid(nearby_player) or home_position.distance_to(nearby_player.global_position) > 110.0):
		player_near = false
		nearby_player = null
		return_delay.start()

	match state:
		State.FLEE:
			_move_to(safe_position, State.WAIT)
		State.RETURN:
			_move_to(home_position, State.WORK)
		_:
			velocity = Vector2.ZERO


func _move_to(target: Vector2, next_state: State) -> void:
	if global_position.distance_to(target) <= 3.0:
		global_position = target
		velocity = Vector2.ZERO
		state = next_state
		if state == State.WORK:
			sprite.flip_h = false
			sprite.play(_standing_animation())
		else:
			sprite.play(work_animation + "_idle")
		return

	velocity = global_position.direction_to(target) * run_speed
	sprite.flip_h = velocity.x < 0.0
	move_and_slide()


func _on_player_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_near = true
	nearby_player = body
	return_delay.stop()
	state = State.FLEE
	sprite.play(work_animation + "_run")
	if speech_cooldown.is_stopped():
		speech_bubble.show()
		speech_timer.start()
		speech_cooldown.start()


func _return_to_work() -> void:
	if player_near:
		return

	state = State.RETURN
	sprite.play(work_animation + "_run")


func _add_idle_animation() -> void:
	var animation := StringName(work_animation + "_idle")
	if sprite.sprite_frames.has_animation(animation):
		return

	sprite.sprite_frames.add_animation(animation)
	sprite.sprite_frames.set_animation_speed(animation, 8.0)
	for index in 8:
		var frame := AtlasTexture.new()
		frame.atlas = IDLE_TEXTURES[work_animation]
		frame.region = Rect2(index * 192, 0, 192, 192)
		sprite.sprite_frames.add_frame(animation, frame)


func _add_gold_run_animation() -> void:
	if work_animation != "gold" or sprite.sprite_frames.has_animation(&"gold_run"):
		return

	sprite.sprite_frames.add_animation(&"gold_run")
	sprite.sprite_frames.set_animation_speed(&"gold_run", 8.0)
	for index in 6:
		var frame := AtlasTexture.new()
		frame.atlas = GOLD_RUN_TEXTURE
		frame.region = Rect2(index * 192, 0, 192, 192)
		sprite.sprite_frames.add_frame(&"gold_run", frame)


func _standing_animation() -> StringName:
	return StringName(work_animation + "_idle") if work_animation == "gold" else StringName(work_animation)
