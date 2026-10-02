extends NavigationRegion2D

@export var agent_radius := 24.0
@export_flags_2d_physics var obstacle_mask := 1


func _ready() -> void:
	_build_navigation.call_deferred()


func _build_navigation() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var bounds := _get_tilemap_bounds(scene_root)
	if not bounds.has_area():
		return

	var polygon := NavigationPolygon.new()
	polygon.agent_radius = agent_radius
	polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	polygon.parsed_collision_mask = obstacle_mask
	polygon.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	polygon.add_outline(PackedVector2Array([
		bounds.position,
		Vector2(bounds.position.x, bounds.end.y),
		bounds.end,
		Vector2(bounds.end.x, bounds.position.y),
	]))

	var source := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(
		polygon,
		source,
		scene_root,
		_on_geometry_parsed.bind(polygon, source)
	)


func _on_geometry_parsed(polygon: NavigationPolygon, source: NavigationMeshSourceGeometryData2D) -> void:
	NavigationServer2D.bake_from_source_geometry_data_async(
		polygon,
		source,
		_on_navigation_baked.bind(polygon)
	)


func _on_navigation_baked(polygon: NavigationPolygon) -> void:
	navigation_polygon = polygon


func _get_tilemap_bounds(scene_root: Node) -> Rect2:
	var bounds := Rect2()
	var found := false
	for node in scene_root.find_children("*", "TileMapLayer", true, false):
		var layer := node as TileMapLayer
		var used := layer.get_used_rect()
		if not used.has_area():
			continue
		var tile_size := Vector2(layer.tile_set.tile_size)
		var top_left := to_local(layer.to_global(layer.map_to_local(used.position))) - tile_size * 0.5
		var bottom_right_cell := used.position + used.size - Vector2i.ONE
		var bottom_right := to_local(layer.to_global(layer.map_to_local(bottom_right_cell))) + tile_size * 0.5
		var layer_bounds := Rect2(top_left, bottom_right - top_left)
		bounds = layer_bounds if not found else bounds.merge(layer_bounds)
		found = true
	return bounds
