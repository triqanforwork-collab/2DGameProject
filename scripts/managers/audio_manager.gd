extends Node

const SFX_ROOT := "res://assets/audio/sfx/game/"
const SFX := {
	&"sword_swing": "sword_swing.wav", &"dash": "dash.wav", &"hit": "hit.wav",
	&"player_hurt": "player_hurt.wav", &"enemy_attack": "enemy_attack.wav",
	&"enemy_hurt": "enemy_hurt.wav", &"enemy_death": "enemy_death.wav",
	&"energy_pickup": "energy_pickup.wav", &"upgrade": "upgrade.wav",
	&"stone_activate": "stone_activate.wav", &"ui_click": "ui_click.wav", &"denied": "denied.wav",
	&"magic_cast": "magic_cast.wav", &"heal": "heal.wav", &"staff_beam": "staff_beam.wav",
	&"weapon_switch": "weapon_switch.wav", &"ultimate_cast": "ultimate_cast.wav",
	&"ultimate_explosion": "ultimate_explosion.wav", &"bomb_throw": "bomb_throw.wav",
	&"bomb_fuse": "bomb_fuse.wav", &"bomb_explosion": "bomb_explosion.wav",
	&"boss_warning": "boss_warning.wav", &"boss_spawn": "boss_spawn.wav",
	&"boss_phase": "boss_phase.wav", &"water_shot": "water_shot.wav",
	&"water_impact": "water_impact.wav", &"boss_laser": "boss_laser.wav",
	&"earth_slam": "earth_slam.wav", &"earth_wave": "earth_wave.wav",
	&"rock_impact": "rock_impact.wav", &"light_slash": "light_slash.wav",
	&"light_burst": "light_burst.wav", &"wind": "wind.wav", &"tornado": "tornado.wav",
	&"fireball": "fireball.wav", &"energy_storm": "energy_storm.wav",
	&"life_drain": "life_drain.wav",
}

var last_played: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func play_sfx(key: StringName, pitch := 1.0, volume_db := 0.0) -> AudioStreamPlayer:
	if not SFX.has(key):
		return null
	var now := Time.get_ticks_msec()
	if now - int(last_played.get(key, -1000)) < 60:
		return null
	last_played[key] = now
	var stream := load(SFX_ROOT + str(SFX[key])) as AudioStream
	if stream == null:
		return null
	var player := AudioStreamPlayer.new()
	player.bus = &"SFX"
	player.stream = stream
	player.pitch_scale = clampf(pitch, 0.5, 2.0)
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
	return player
