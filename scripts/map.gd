extends Sprite2D

var map_scale = 0.25
var points: Array[Vector2] = [] 
var discovery_dist = 10.0 
var max_points = 2000
var map_size = Vector2(190, 134)

var is_powered: bool = true
func _draw():
	var half_size = map_size / 2.0
	draw_rect(Rect2(-half_size.x+1, -half_size.y+1, map_size.x-2, map_size.y-2), Color(0, 0, 0, 1.0))
	if not is_powered:
		return 
	var my_pos = global_position
	var dot_size = Vector2(1.5, 1.5)
	
	for p in points:
		var local_p = (p - my_pos) * map_scale
		if abs(local_p.x) < half_size.x and abs(local_p.y) < half_size.y:
			draw_rect(Rect2(local_p, dot_size), Color.GHOST_WHITE)
	draw_rect(Rect2(Vector2(-2, -2), Vector2(4, 4)), Color.RED)

func add_point(global_pos: Vector2):
	var check_count = min(points.size(), 40)
	for i in range(points.size() - 1, points.size() - 1 - check_count, -1):
		if i < 0: break
		if points[i].distance_to(global_pos) < discovery_dist:
			return
	
	points.append(global_pos)
	if points.size() > max_points:
		points.remove_at(0)

func _process(_delta):
	if visible:
		queue_redraw()
