extends Node

signal energy_changed(current_energy: int)

var carried_energy := 0


func add_energy(amount: int) -> void:
	if amount <= 0:
		return

	carried_energy += amount
	SaveManager.record_energy(amount)
	energy_changed.emit(carried_energy)


func deposit_energy(amount: int) -> int:
	if amount <= 0:
		return 0

	var deposited := mini(amount, carried_energy)
	carried_energy -= deposited
	energy_changed.emit(carried_energy)
	return deposited

func reset_energy() -> void:
	carried_energy = 0
	energy_changed.emit(carried_energy)


func set_energy(amount: int) -> void:
	carried_energy = maxi(amount, 0)
	energy_changed.emit(carried_energy)
