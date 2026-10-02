class_name RegionEncounterController
extends Node

signal remaining_minions_changed(remaining: int)
signal boss_spawned(boss: Node)

enum EncounterState {
	CLEARING,
	WARNING,
	BOSS_ACTIVE,
	COMPLETED,
}

const BOSS_SPAWN_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/BossSpawnEffect.tscn")

@export var enemies_container_path: NodePath
@export var boss_container_path: NodePath
@export var boss_spawn_point_path: NodePath
@export var boss_scene: PackedScene
@export var boss_display_name := "BOSS"
@export_range(0.1, 5.0, 0.1) var warning_hold_duration := 1.7
@export_range(0.1, 2.0, 0.05) var camera_pan_duration := 0.65
@export_range(0.1, 2.0, 0.05) var camera_return_duration := 0.5

@onready var warning_overlay: BossWarningOverlay = $BossWarningOverlay
@onready var combat_music: AudioStreamPlayer = $CombatMusic

var encounter_state := EncounterState.CLEARING
var enemies_container: Node
var boss_container: Node2D
var boss_spawn_point: Node2D
var tracked_minions: Dictionary = {}
var player: Node2D
var spawned_boss: Node


func _ready() -> void:
	_enable_music_loop(combat_music)
	call_deferred("_initialize_encounter")


func _enable_music_loop(player_node: AudioStreamPlayer) -> void:
	if player_node.stream is AudioStreamWAV:
		(player_node.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	if not player_node.finished.is_connected(player_node.play):
		player_node.finished.connect(player_node.play)
	if not player_node.playing:
		player_node.play()


func _initialize_encounter() -> void:
	enemies_container = get_node_or_null(enemies_container_path)
	boss_container = get_node_or_null(boss_container_path) as Node2D
	boss_spawn_point = get_node_or_null(boss_spawn_point_path) as Node2D
	player = get_tree().get_first_node_in_group("player") as Node2D

	if enemies_container == null or boss_container == null or boss_spawn_point == null:
		push_error("RegionEncounterController is missing a required map node path.")
		return
	if boss_scene == null:
		push_error("RegionEncounterController has no boss scene configured.")
		return

	if not enemies_container.child_entered_tree.is_connected(_on_enemy_container_child_entered):
		enemies_container.child_entered_tree.connect(_on_enemy_container_child_entered)

	for candidate in enemies_container.get_children():
		_register_minion(candidate)

	remaining_minions_changed.emit(tracked_minions.size())
	_check_for_region_clear()


func _on_enemy_container_child_entered(candidate: Node) -> void:
	_register_minion.call_deferred(candidate)


func _register_minion(candidate: Node) -> void:
	if encounter_state != EncounterState.CLEARING or not is_instance_valid(candidate):
		return
	if not candidate.is_in_group("enemy") or candidate.is_in_group("boss"):
		return

	var instance_id := candidate.get_instance_id()
	if tracked_minions.has(instance_id):
		return

	tracked_minions[instance_id] = true
	candidate.tree_exited.connect(_on_minion_tree_exited.bind(instance_id), CONNECT_ONE_SHOT)
	remaining_minions_changed.emit(tracked_minions.size())


func _on_minion_tree_exited(instance_id: int) -> void:
	tracked_minions.erase(instance_id)
	remaining_minions_changed.emit(tracked_minions.size())
	_check_for_region_clear.call_deferred()


func _check_for_region_clear() -> void:
	if encounter_state != EncounterState.CLEARING:
		return
	if not tracked_minions.is_empty():
		return
	_begin_boss_warning.call_deferred()


func _begin_boss_warning() -> void:
	if encounter_state != EncounterState.CLEARING or not tracked_minions.is_empty():
		return

	encounter_state = EncounterState.WARNING
	var warning_sound := AudioManager.play_sfx(&"boss_warning")
	_set_player_locked(true)

	var camera := _get_player_camera()
	var original_camera_position := Vector2.ZERO
	var target_camera_position := Vector2.ZERO
	if camera != null:
		original_camera_position = camera.position
		target_camera_position = camera.get_parent().to_local(boss_spawn_point.global_position)
		var pan_tween := create_tween()
		pan_tween.set_trans(Tween.TRANS_SINE)
		pan_tween.set_ease(Tween.EASE_IN_OUT)
		pan_tween.tween_property(camera, "position", target_camera_position, camera_pan_duration)

	await warning_overlay.play_warning(boss_display_name, warning_hold_duration)
	if is_instance_valid(warning_sound):
		warning_sound.stop()
		warning_sound.queue_free()

	var spawn_effect := BOSS_SPAWN_EFFECT_SCENE.instantiate() as BossSpawnEffect
	AudioManager.play_sfx(&"boss_spawn")
	boss_container.add_child(spawn_effect)
	spawn_effect.global_position = boss_spawn_point.global_position
	spawn_effect.play()
	_shake_camera(camera, target_camera_position)
	await spawn_effect.reveal_requested
	spawned_boss = _spawn_boss()
	await spawn_effect.finished

	if camera != null and is_instance_valid(camera):
		var return_tween := create_tween()
		return_tween.set_trans(Tween.TRANS_SINE)
		return_tween.set_ease(Tween.EASE_IN_OUT)
		return_tween.tween_property(camera, "position", original_camera_position, camera_return_duration)
		await return_tween.finished

	if is_instance_valid(spawned_boss):
		spawned_boss.process_mode = Node.PROCESS_MODE_INHERIT
	encounter_state = EncounterState.BOSS_ACTIVE
	_set_player_locked(false)


func _spawn_boss() -> Node:
	var boss := boss_scene.instantiate()
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	boss_container.add_child(boss)
	if boss is Node2D:
		boss.global_position = boss_spawn_point.global_position
	boss_spawned.emit(boss)
	return boss


func _get_player_camera() -> Camera2D:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return null
	return player.get_node_or_null("Camera2D") as Camera2D


func _set_player_locked(locked: bool) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(player) and player.has_method("set_cinematic_locked"):
		player.call("set_cinematic_locked", locked)


func _shake_camera(camera: Camera2D, center_position: Vector2) -> void:
	if camera == null:
		return

	var shake_tween := create_tween()
	shake_tween.tween_property(camera, "position", center_position + Vector2(8, -5), 0.05)
	shake_tween.tween_property(camera, "position", center_position + Vector2(-7, 6), 0.05)
	shake_tween.tween_property(camera, "position", center_position + Vector2(5, 4), 0.05)
	shake_tween.tween_property(camera, "position", center_position + Vector2(-4, -3), 0.05)
	shake_tween.tween_property(camera, "position", center_position, 0.08)


func _exit_tree() -> void:
	_set_player_locked(false)
