extends Control

const SWORD_ICON: Texture2D = preload("res://assets/ui/Icons/sword_icon.png")
const STAFF_ICON: Texture2D = preload("res://assets/ui/Icons/Icon_02.png")

@export var joystick_radius: float = 58.0
@export_range(0.0, 0.9, 0.01) var joystick_deadzone: float = 0.12
@export var dynamic_joystick: bool = true
@export var edge_margin: float = 20.0

@onready var joystick_zone: Control = $VirtualJoystickZone
@onready var joystick_base: Control = $VirtualJoystickZone/Base
@onready var joystick_knob: Control = $VirtualJoystickZone/Knob
@onready var attack_button: Button = $ActionButtons/AttackButton
@onready var dash_button: Button = $ActionButtons/DashButton
@onready var dash_cooldown_label: Label = $ActionButtons/DashCooldown
@onready var skill_button: Button = $ActionButtons/SkillButton
@onready var skill_status_label: Label = $ActionButtons/SkillLock
@onready var weapon_switch_button: Button = $ActionButtons/WeaponSwitchButton
@onready var weapon_switch_status_label: Label = $ActionButtons/WeaponSwitchButton/WeaponSwitchLock
@onready var area_attack_button: Button = $ActionButtons/AreaAttackButton
@onready var area_attack_status_label: Label = $ActionButtons/AreaAttackLock
@onready var interact_button: Button = $ActionButtons/InteractButton

var player: Node
var joystick_touch_index := -1
var joystick_mouse_active := false
var joystick_center := Vector2.ZERO
var controls_enabled := true
var interactable_available := false


func _ready() -> void:
	attack_button.button_down.connect(_press_action.bind("attack"))
	attack_button.button_up.connect(_release_action.bind("attack"))
	dash_button.button_down.connect(_press_action.bind("dash"))
	dash_button.button_up.connect(_release_action.bind("dash"))
	skill_button.button_down.connect(_press_action.bind("heal"))
	skill_button.button_up.connect(_release_action.bind("heal"))
	weapon_switch_button.button_down.connect(_press_action.bind("switch_weapon"))
	weapon_switch_button.button_up.connect(_release_action.bind("switch_weapon"))
	area_attack_button.button_down.connect(_press_action.bind("area_attack"))
	area_attack_button.button_up.connect(_release_action.bind("area_attack"))
	interact_button.button_down.connect(_press_action.bind("interact"))
	interact_button.button_up.connect(_release_action.bind("interact"))

	skill_button.disabled = true
	weapon_switch_button.disabled = true
	area_attack_button.disabled = true
	interact_button.visible = false
	get_viewport().size_changed.connect(_apply_safe_area)
	_find_player()
	_apply_safe_area.call_deferred()
	_reset_joystick_visual.call_deferred()


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		_find_player()
		return

	_set_controls_enabled(not bool(player.get("is_dead")) and not bool(player.get("controls_locked")))
	_update_dash_cooldown()
	_update_ability_buttons()


func _input(event: InputEvent) -> void:
	if not controls_enabled:
		return

	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and joystick_mouse_active:
		_update_joystick(event.position)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if joystick_touch_index == -1 and joystick_zone.get_global_rect().has_point(event.position):
			joystick_touch_index = event.index
			_begin_joystick(event.position)
	elif event.index == joystick_touch_index:
		joystick_touch_index = -1
		_release_joystick()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_index:
		_update_joystick(event.position)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		if joystick_zone.get_global_rect().has_point(event.position):
			joystick_mouse_active = true
			_begin_joystick(event.position)
	elif joystick_mouse_active:
		joystick_mouse_active = false
		_release_joystick()


func _begin_joystick(screen_position: Vector2) -> void:
	if dynamic_joystick:
		var local_position := joystick_zone.get_global_transform().affine_inverse() * screen_position
		var half_base := joystick_base.size * 0.5
		joystick_center = Vector2(
			clampf(local_position.x, half_base.x, joystick_zone.size.x - half_base.x),
			clampf(local_position.y, half_base.y, joystick_zone.size.y - half_base.y)
		)
		joystick_base.position = joystick_center - half_base

	_update_joystick(screen_position)


func _update_joystick(screen_position: Vector2) -> void:
	var local_position := joystick_zone.get_global_transform().affine_inverse() * screen_position
	var offset := (local_position - joystick_center).limit_length(joystick_radius)
	joystick_knob.position = joystick_center + offset - joystick_knob.size * 0.5

	var input_vector := offset / joystick_radius
	if input_vector.length() < joystick_deadzone:
		input_vector = Vector2.ZERO
	else:
		var strength := inverse_lerp(joystick_deadzone, 1.0, input_vector.length())
		input_vector = input_vector.normalized() * strength

	_set_movement_actions(input_vector)


func _release_joystick() -> void:
	_release_movement_actions()
	_reset_joystick_visual()


func _reset_joystick_visual() -> void:
	if not is_node_ready():
		return

	joystick_center = joystick_zone.size * 0.5
	joystick_base.position = joystick_center - joystick_base.size * 0.5
	joystick_knob.position = joystick_center - joystick_knob.size * 0.5


func _set_movement_actions(input_vector: Vector2) -> void:
	_set_action_strength("move_left", maxf(-input_vector.x, 0.0))
	_set_action_strength("move_right", maxf(input_vector.x, 0.0))
	_set_action_strength("move_up", maxf(-input_vector.y, 0.0))
	_set_action_strength("move_down", maxf(input_vector.y, 0.0))


func _set_action_strength(action_name: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action_name, strength)
	else:
		Input.action_release(action_name)


func _press_action(action_name: StringName) -> void:
	if controls_enabled:
		Input.action_press(action_name)


func _release_action(action_name: StringName) -> void:
	Input.action_release(action_name)


func _release_movement_actions() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")


func _find_player() -> void:
	var candidate := get_parent().get_parent()
	if candidate == null or not candidate.has_signal("interaction_availability_changed"):
		return

	player = candidate
	if not player.interaction_availability_changed.is_connected(_on_interaction_availability_changed):
		player.interaction_availability_changed.connect(_on_interaction_availability_changed)
	if player.has_signal("weapon_mode_changed") and not player.weapon_mode_changed.is_connected(_on_weapon_mode_changed):
		player.weapon_mode_changed.connect(_on_weapon_mode_changed)
	_on_interaction_availability_changed(bool(player.call("has_available_interactable")))
	_on_weapon_mode_changed(int(player.get("weapon_mode")))


func _on_interaction_availability_changed(available: bool) -> void:
	interactable_available = available
	interact_button.visible = available
	interact_button.disabled = not controls_enabled or not available


func _on_weapon_mode_changed(mode: int) -> void:
	var staff_equipped := mode == 1
	attack_button.icon = STAFF_ICON if staff_equipped else SWORD_ICON
	weapon_switch_button.tooltip_text = "Switch to Sword" if staff_equipped else "Switch to Staff"


func _set_controls_enabled(enabled: bool) -> void:
	if controls_enabled == enabled:
		return

	controls_enabled = enabled
	attack_button.disabled = not enabled
	skill_button.disabled = not enabled or not bool(player.get("heal_unlocked"))
	weapon_switch_button.disabled = not enabled or not bool(player.get("staff_unlocked"))
	area_attack_button.disabled = not enabled or not bool(player.get("area_attack_unlocked"))
	interact_button.disabled = not enabled or not interactable_available

	if not enabled:
		dash_button.disabled = true
		joystick_touch_index = -1
		joystick_mouse_active = false
		_release_joystick()
		Input.action_release("attack")
		Input.action_release("dash")
		Input.action_release("heal")
		Input.action_release("switch_weapon")
		Input.action_release("area_attack")
		Input.action_release("interact")


func _update_dash_cooldown() -> void:
	var cooldown_left := maxf(float(player.get("dash_cooldown_left")), 0.0)
	if cooldown_left > 0.0:
		dash_button.disabled = true
		dash_cooldown_label.text = "%.1f" % cooldown_left
	else:
		dash_button.disabled = not controls_enabled
		dash_cooldown_label.text = ""


func _update_ability_buttons() -> void:
	var heal_available := bool(player.get("heal_unlocked"))
	var heal_cooldown_left := maxf(float(player.get("heal_cooldown_left")), 0.0)
	var staff_available := bool(player.get("staff_unlocked"))
	var area_attack_available := bool(player.get("area_attack_unlocked"))
	var area_attack_cooldown_left := maxf(float(player.get("area_attack_cooldown_left")), 0.0)
	skill_button.disabled = not controls_enabled or not heal_available or heal_cooldown_left > 0.0
	weapon_switch_button.disabled = not controls_enabled or not staff_available
	area_attack_button.disabled = not controls_enabled or not area_attack_available or area_attack_cooldown_left > 0.0

	if not heal_available:
		skill_status_label.visible = true
		skill_status_label.text = "LOCKED"
		skill_button.tooltip_text = "Heal (Locked)"
	elif heal_cooldown_left > 0.0:
		skill_status_label.visible = true
		skill_status_label.text = "%.1f" % heal_cooldown_left
		skill_button.tooltip_text = "Heal (Cooldown)"
	else:
		skill_status_label.visible = false
		skill_status_label.text = ""
		skill_button.tooltip_text = "Heal"

	weapon_switch_status_label.visible = not staff_available
	weapon_switch_status_label.text = "LOCKED" if not staff_available else ""
	if not staff_available:
		weapon_switch_button.tooltip_text = "Switch Weapon (Locked)"
	else:
		weapon_switch_button.tooltip_text = "Switch to Sword" if int(player.get("weapon_mode")) == 1 else "Switch to Staff"

	if not area_attack_available:
		area_attack_status_label.visible = true
		area_attack_status_label.text = "LOCKED"
		area_attack_button.tooltip_text = "Area Attack (Locked)"
	elif area_attack_cooldown_left > 0.0:
		area_attack_status_label.visible = true
		area_attack_status_label.text = "%.1f" % area_attack_cooldown_left
		area_attack_button.tooltip_text = "Area Attack (Cooldown)"
	else:
		area_attack_status_label.visible = false
		area_attack_status_label.text = ""
		area_attack_button.tooltip_text = "Area Attack"


func _apply_safe_area() -> void:
	if OS.get_name() not in ["Android", "iOS"]:
		return

	var screen_size := Vector2(DisplayServer.screen_get_size())
	if screen_size.x <= 0.0 or screen_size.y <= 0.0:
		return

	var safe_area := DisplayServer.get_display_safe_area()
	var viewport_size := get_viewport_rect().size
	var viewport_scale := viewport_size / screen_size
	var left_inset := maxf(float(safe_area.position.x), 0.0) * viewport_scale.x
	var right_inset := maxf(screen_size.x - float(safe_area.position.x + safe_area.size.x), 0.0) * viewport_scale.x
	var bottom_inset := maxf(screen_size.y - float(safe_area.position.y + safe_area.size.y), 0.0) * viewport_scale.y

	joystick_zone.offset_left = edge_margin + left_inset
	joystick_zone.offset_right = joystick_zone.offset_left + 220.0
	joystick_zone.offset_bottom = -(edge_margin + bottom_inset)
	joystick_zone.offset_top = joystick_zone.offset_bottom - 220.0

	$ActionButtons.offset_right = -(edge_margin + right_inset)
	$ActionButtons.offset_left = $ActionButtons.offset_right - 284.0
	$ActionButtons.offset_bottom = -(edge_margin + bottom_inset)
	$ActionButtons.offset_top = $ActionButtons.offset_bottom - 228.0


func _exit_tree() -> void:
	_release_movement_actions()
	Input.action_release("attack")
	Input.action_release("dash")
	Input.action_release("heal")
	Input.action_release("switch_weapon")
	Input.action_release("area_attack")
	Input.action_release("interact")
