extends Sprite2D

var frame_size := Vector2i.ONE
var frame_count := 1
var fps := 18.0
var loop := false
var elapsed := 0.0


func setup(sheet: Texture2D, size: Vector2i, count: int, animation_fps: float, should_loop := false, visual_scale := Vector2.ONE, tint := Color.WHITE) -> void:
	z_index = 30
	texture = sheet
	frame_size = size
	frame_count = count
	fps = animation_fps
	loop = should_loop
	scale = visual_scale
	modulate = tint
	region_enabled = true
	region_rect = Rect2(Vector2.ZERO, Vector2(frame_size))


func _process(delta: float) -> void:
	elapsed += delta
	var frame := int(elapsed * fps)
	if loop:
		frame %= frame_count
	elif frame >= frame_count:
		queue_free()
		return
	var next_region := region_rect
	next_region.position.x = frame * frame_size.x
	region_rect = next_region
