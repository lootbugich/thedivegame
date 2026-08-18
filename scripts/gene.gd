extends TileMap

@export var map_width := 40
@export var map_height := 40
@export var fill_percent := 45
@export var smoothing_iterations := 4
@export var room_radius := 4
@export var max_generation_attempts := 16
@export var should_be_closed := true

var _map := {}
var _start_point: Vector2i
var _end_point: Vector2i

func generate_level(start: Vector2i, end: Vector2i) -> void:
	print("=== GEN START: ", start, " -> ", end, " ===")
	_start_point = start
	_end_point = end

	var attempt := 0
	var valid_map := false

	while !valid_map and attempt < max_generation_attempts:
		attempt += 1
		print("Attempt #", attempt)
		clear()
		_map.clear()
		_initialize_map(attempt)
		for i in smoothing_iterations:
			_smooth_map()
		_create_room(_start_point, room_radius)
		_create_room(_end_point, room_radius)
		valid_map = _check_path_exists()
		print("Path found: ", valid_map)

	if !valid_map:
		push_error("Failed after %d attempts" % max_generation_attempts)

	if should_be_closed:
		_force_walls()

	_apply_to_tilemap()
	print("=== GEN DONE ===")

func _initialize_map(seed_value: int) -> void:
	seed(seed_value)
	for x in range(map_width):
		for y in range(map_height):
			var pos := Vector2i(x, y)
			if x == 0 or x == map_width - 1 or y == 0 or y == map_height - 1:
				_map[pos] = true
			else:
				_map[pos] = randf() * 100 < fill_percent

func _smooth_map() -> void:
	var new_map := {}
	for x in range(map_width):
		for y in range(map_height):
			var pos := Vector2i(x, y)
			var wall_count := _get_surrounding_wall_count(pos)
			if wall_count > 4:
				new_map[pos] = true
			elif wall_count < 4:
				new_map[pos] = false
			else:
				new_map[pos] = _map.get(pos, true)
	_map = new_map

func _get_surrounding_wall_count(pos: Vector2i) -> int:
	var wall_count := 0
	for x in range(-1, 2):
		for y in range(-1, 2):
			var check_pos := Vector2i(pos.x + x, pos.y + y)
			if check_pos != pos:
				if _map.get(check_pos, true):
					wall_count += 1
	return wall_count

func _create_room(center: Vector2i, radius: int) -> void:
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var pos := Vector2i(center.x + x, center.y + y)
			if pos.x >= 0 and pos.x < map_width and pos.y >= 0 and pos.y < map_height:
				if Vector2(x, y).length() <= radius:
					_map[pos] = false

func _check_path_exists() -> bool:
	var astar := AStar2D.new()
	for x in range(map_width):
		for y in range(map_height):
			var pos := Vector2i(x, y)
			if not _map.get(pos, true):
				astar.add_point(_get_point_id(pos), pos)

	for x in range(map_width):
		for y in range(map_height):
			var pos := Vector2i(x, y)
			if not _map.get(pos, true):
				var point_id := _get_point_id(pos)
				for n in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var next := Vector2i(pos.x + n.x, pos.y + n.y)
					if _is_valid_empty(next):
						var next_id := _get_point_id(next)
						if not astar.are_points_connected(point_id, next_id):
							astar.connect_points(point_id, next_id)

	var start_id := _get_point_id(_start_point)
	var end_id := _get_point_id(_end_point)
	return astar.has_point(start_id) and astar.has_point(end_id) and astar.get_point_path(start_id, end_id).size() > 0

func _is_valid_empty(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < map_width and pos.y >= 0 and pos.y < map_height and not _map.get(pos, true)

func _get_point_id(pos: Vector2i) -> int:
	return pos.x + pos.y * map_width

func _force_walls() -> void:
	for x in range(map_width):
		_map[Vector2i(x, 0)] = true
		_map[Vector2i(x, map_height - 1)] = true
	for y in range(map_height):
		_map[Vector2i(0, y)] = true
		_map[Vector2i(map_width - 1, y)] = true

func _apply_to_tilemap() -> void:
	var walls := 0
	var empty := 0
	for x in range(map_width):
		for y in range(map_height):
			var pos := Vector2i(x, y)
			if _map.get(pos, true):
				set_cell(0, pos, 0)
				walls += 1
			else:
				erase_cell(0, pos)
				empty += 1
	print("Tiles placed: walls=", walls, " empty=", empty)
