extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const DISPLAY_DURATION := 3.2
const FADE_IN_DURATION := 0.8
const FADE_OUT_DURATION := 0.45

@onready var fade_rect: ColorRect = $FadeRect
@onready var title_label: Label = $TitleBlock/TitleLabel
@onready var subtitle_label: Label = $TitleBlock/SubtitleLabel
@onready var tree_mark: TextureRect = $TreeMark
@onready var skip_hint: Label = $SkipHint
@onready var core_lights: Array[ColorRect] = [
	$CoreRing/WaterCore,
	$CoreRing/EarthCore,
	$CoreRing/LightCore,
	$CoreRing/AirCore,
	$CoreRing/LifeCore,
]

var elapsed_time := 0.0
var is_transitioning := false


func _ready() -> void:
	modulate.a = 1.0
	fade_rect.color.a = 1.0
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	tree_mark.modulate.a = 0.0
	skip_hint.modulate.a = 0.0

	await get_tree().process_frame
	title_label.pivot_offset = title_label.size * 0.5
	tree_mark.pivot_offset = tree_mark.size * 0.5

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 0.0, FADE_IN_DURATION)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.65).set_delay(0.15)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.55).set_delay(0.55)
	tween.tween_property(tree_mark, "modulate:a", 0.78, 0.8).set_delay(0.25)
	tween.tween_property(skip_hint, "modulate:a", 0.72, 0.4).set_delay(1.1)


func _process(delta: float) -> void:
	if is_transitioning:
		return

	elapsed_time += delta
	if elapsed_time >= DISPLAY_DURATION:
		_go_to_main_menu()
		return

	var pulse := (sin(elapsed_time * 4.5) + 1.0) * 0.5
	tree_mark.scale = Vector2.ONE * lerpf(0.985, 1.015, pulse)
	skip_hint.modulate.a = lerpf(0.4, 0.85, pulse)

	for index in core_lights.size():
		var core := core_lights[index]
		var core_pulse := (sin(elapsed_time * 3.2 + float(index) * 0.9) + 1.0) * 0.5
		core.modulate.a = lerpf(0.35, 1.0, core_pulse)
		core.scale = Vector2.ONE * lerpf(0.85, 1.18, core_pulse)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_go_to_main_menu()
	elif event is InputEventMouseButton and event.pressed:
		_go_to_main_menu()
	elif event is InputEventScreenTouch and event.pressed:
		_go_to_main_menu()


func _go_to_main_menu() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, FADE_OUT_DURATION)
	await tween.finished
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
