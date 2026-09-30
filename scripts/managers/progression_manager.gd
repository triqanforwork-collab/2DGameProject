extends Node

signal progression_reset
signal stone_energy_changed(stone_id: StringName, current_energy: int, required_energy: int)
signal boss_defeated(region_id: StringName)
signal stone_activated(stone_id: StringName, reward_id: StringName)
signal region_unlocked(region_id: StringName)
signal reward_unlocked(reward_id: StringName)
signal stat_upgrade_changed(stone_id: StringName, level: int)
signal game_completed

const STONE_ORDER: Array[StringName] = [
	&"water",
	&"earth",
	&"light",
	&"air",
	&"life",
]

const STONE_DATA := {
	&"water": {
		"display_name": "Water Stone",
		"required_energy": 100,
		"boss_name": "Turtle",
		"reward_id": &"heal",
		"reward_description": "Mở khóa kỹ năng hồi máu",
		"next_region": &"earth",
	},
	&"earth": {
		"display_name": "Earth Stone",
		"required_energy": 150,
		"boss_name": "Panda",
		"reward_id": &"staff",
		"reward_description": "Mở khóa quyền trượng tấn công xa",
		"next_region": &"light",
	},
	&"light": {
		"display_name": "Light Stone",
		"required_energy": 200,
		"boss_name": "Minotaur",
		"reward_id": &"area_attack",
		"reward_description": "Mở khóa kỹ năng tấn công diện rộng",
		"next_region": &"air",
	},
	&"air": {
		"display_name": "Air Stone",
		"required_energy": 250,
		"boss_name": "Giant Bat",
		"reward_id": &"stat_upgrades",
		"reward_description": "Mở khóa hệ thống nâng chỉ số",
		"next_region": &"life",
	},
	&"life": {
		"display_name": "Life Stone",
		"required_energy": 300,
		"boss_name": "Troll",
		"reward_id": &"victory",
		"reward_description": "Hoàn thành trò chơi",
		"next_region": &"",
	},
}

const UPGRADE_COSTS: Array[int] = [25, 50, 75, 100, 125]
const STONE_UPGRADE_DATA := {
	&"water": {"stat_name": "Max Mana", "bonus_text": "+10 Max Mana mỗi cấp"},
	&"earth": {"stat_name": "Hồi máu", "bonus_text": "+5 HP hồi mỗi cấp"},
	&"light": {"stat_name": "Sát thương vũ khí", "bonus_text": "+10 kiếm và +2 trượng mỗi cấp"},
	&"air": {"stat_name": "Sát thương Ulti", "bonus_text": "+15 damage mỗi cấp"},
	&"life": {"stat_name": "Max HP", "bonus_text": "+10 Max HP mỗi cấp"},
}

var stone_energy: Dictionary = {}
var defeated_bosses: Dictionary = {}
var activated_stones: Dictionary = {}
var unlocked_regions: Dictionary = {}
var unlocked_rewards: Dictionary = {}
var stat_upgrade_levels: Dictionary = {}
var has_completed_game := false


func _ready() -> void:
	reset_progression()


func reset_progression() -> void:
	stone_energy.clear()
	defeated_bosses.clear()
	activated_stones.clear()
	unlocked_regions.clear()
	unlocked_rewards.clear()
	stat_upgrade_levels.clear()
	has_completed_game = false

	for stone_id in STONE_ORDER:
		stone_energy[stone_id] = 0
		defeated_bosses[stone_id] = false
		activated_stones[stone_id] = false
		stat_upgrade_levels[stone_id] = 0

	unlocked_regions[&"water"] = true
	progression_reset.emit()
	region_unlocked.emit(&"water")


func get_current_stone_id() -> StringName:
	for stone_id in STONE_ORDER:
		if not bool(activated_stones.get(stone_id, false)):
			return stone_id
	return &""


func get_stone_data(stone_id: StringName) -> Dictionary:
	return STONE_DATA.get(stone_id, {})


func get_stone_energy(stone_id: StringName) -> int:
	return int(stone_energy.get(stone_id, 0))


func get_required_energy(stone_id: StringName) -> int:
	return int(get_stone_data(stone_id).get("required_energy", 0))


func is_boss_defeated(region_id: StringName) -> bool:
	return bool(defeated_bosses.get(region_id, false))


func is_region_unlocked(region_id: StringName) -> bool:
	return bool(unlocked_regions.get(region_id, false))


func is_reward_unlocked(reward_id: StringName) -> bool:
	return bool(unlocked_rewards.get(reward_id, false))


func get_stat_upgrade_data(stone_id: StringName) -> Dictionary:
	return STONE_UPGRADE_DATA.get(stone_id, {})


func get_stat_upgrade_level(stone_id: StringName) -> int:
	return int(stat_upgrade_levels.get(stone_id, 0))


func get_stat_upgrade_cost(stone_id: StringName) -> int:
	var level := get_stat_upgrade_level(stone_id)
	return UPGRADE_COSTS[level] if level < UPGRADE_COSTS.size() else 0


func purchase_stat_upgrade(stone_id: StringName) -> Dictionary:
	if not is_reward_unlocked(&"stat_upgrades"):
		return {"success": false, "message": "Hãy kích hoạt Air Stone để mở hệ thống nâng chỉ số."}
	if not STONE_UPGRADE_DATA.has(stone_id):
		return {"success": false, "message": "Viên đá này không có nâng cấp."}

	var level := get_stat_upgrade_level(stone_id)
	if level >= UPGRADE_COSTS.size():
		return {"success": false, "message": "Chỉ số này đã đạt cấp tối đa."}

	var cost := UPGRADE_COSTS[level]
	if EnergyManager.carried_energy < cost:
		return {"success": false, "message": "Cần %d Energy để nâng cấp." % cost}

	EnergyManager.deposit_energy(cost)
	level += 1
	stat_upgrade_levels[stone_id] = level
	stat_upgrade_changed.emit(stone_id, level)
	return {"success": true, "message": "Nâng cấp thành công lên cấp %d." % level}


func mark_boss_defeated(region_id: StringName) -> void:
	if not STONE_DATA.has(region_id):
		push_warning("Unknown progression region: %s" % region_id)
		return

	if is_boss_defeated(region_id):
		return

	defeated_bosses[region_id] = true
	boss_defeated.emit(region_id)


func deposit_to_current_stone(requested_amount: int) -> Dictionary:
	var stone_id := get_current_stone_id()
	if stone_id == &"" or requested_amount <= 0:
		return {"stone_id": stone_id, "deposited": 0, "activated": false}

	var required_energy := get_required_energy(stone_id)
	var current_energy := get_stone_energy(stone_id)
	var remaining_energy := maxi(required_energy - current_energy, 0)
	var deposited := EnergyManager.deposit_energy(mini(requested_amount, remaining_energy))

	if deposited > 0:
		stone_energy[stone_id] = current_energy + deposited
		stone_energy_changed.emit(stone_id, get_stone_energy(stone_id), required_energy)

	var activated := try_activate_current_stone()
	return {"stone_id": stone_id, "deposited": deposited, "activated": activated}


func try_activate_current_stone() -> bool:
	var stone_id := get_current_stone_id()
	if stone_id == &"":
		return false

	if get_stone_energy(stone_id) < get_required_energy(stone_id):
		return false
	if not is_boss_defeated(stone_id):
		return false

	_activate_stone(stone_id)
	return true


func _activate_stone(stone_id: StringName) -> void:
	if bool(activated_stones.get(stone_id, false)):
		return

	var data := get_stone_data(stone_id)
	var reward_id := data.get("reward_id", &"") as StringName
	var next_region := data.get("next_region", &"") as StringName
	activated_stones[stone_id] = true
	stone_activated.emit(stone_id, reward_id)

	if reward_id != &"":
		unlocked_rewards[reward_id] = true
		reward_unlocked.emit(reward_id)

	if next_region != &"":
		unlocked_regions[next_region] = true
		region_unlocked.emit(next_region)

	if stone_id == &"life":
		has_completed_game = true
		game_completed.emit()
