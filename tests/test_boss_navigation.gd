extends SceneTree


func _init() -> void:
	call_deferred(&"run_test")


func run_test() -> void:
	var region = load("res://scenes/maps/WaterRegion.tscn").instantiate()
	root.add_child(region)
	current_scene = region
	await create_timer(4.0).timeout

	var navigation: NavigationRegion2D = region.get_node("RegionNavigation")
	assert(navigation.navigation_polygon != null)
	assert(not navigation.navigation_polygon.vertices.is_empty())

	var boss = load("res://scenes/bosses/Water/Turtle.tscn").instantiate()
	region.get_node("TileMap/Bosses").add_child(boss)
	await physics_frame
	assert(boss.navigation_agent != null)
	assert(NavigationServer2D.map_get_iteration_id(boss.navigation_agent.get_navigation_map()) > 0)

	print("Boss navigation smoke test passed.")
	quit()
