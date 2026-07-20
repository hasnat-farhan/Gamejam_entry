extends TileMap

const MAP_SIZE = 48
const GRID_SIZE = 16
const MAX_DEPTH = 4
const SPLIT_PERC = 30
const TILE_IDX_UNSET = -1
const TILE_IDX_WALL = 0
const TILE_IDX_FLOOR = 1
const TORCH_SCENE = preload("res://actors/Torch.tscn")
var rng := RandomNumberGenerator.new()
var all_rooms := []

func _ready():
	rng.randomize()
	
	# Generate the level
	var top_zone = LevelGenZone.new(0, 0, MAP_SIZE, MAP_SIZE, 0) 
	add_child(top_zone)
	# Corridors after but before pillars
	top_zone.make_corridor()
	# Add pillars to each room, maybe
	for room in all_rooms:
		_add_pillars(room)

	# Set player start room & location
	all_rooms.shuffle()
	var start_room = all_rooms[0]
	var px = (start_room["left"] + floor(start_room["width"] / 2))
	var py = (start_room["top"] + floor(start_room["height"] / 2))	
	while true:
		if get_cellv(Vector2i(px, py)) == TILE_IDX_FLOOR: break
		# Keep trying to the right
		px += 1
	$Player.position.x = px * GRID_SIZE
	$Player.position.y = py * GRID_SIZE
	
	# Draw walls on edges of rooms
	_add_walls()
					
																			
func fill_cells(left, top, width, height, tile_idx, tile_coords):
	for y in range(top, top + height):
		for x in range(left, left + width):
			set_cellv(Vector2i(x, y), tile_idx, tile_coords, 0)


func fill_cells_floor(left, top, width, height):
	for y in range(top, top + height):
		for x in range(left, left + width):
			set_cellv(Vector2i(x, y), TILE_IDX_FLOOR, Vector2i(rng.randi_range(0, 3), rng.randi_range(0, 2)), 0)
		
			
func _add_pillars(room):
	if room.width * room.height > 15 and room.width > 4 and room.height > 4:
		var deco_count := rng.randi_range(3, 8)
		for p in range(deco_count):
			var pillarLeft := rng.randi_range(1, room.width - 3)
			var pillarTop := rng.randi_range(1, room.height - 3)
			fill_cells(room.left + pillarLeft, room.top + pillarTop, 2, 2, -1, Vector2i.ZERO)

func _add_walls():
	for y in range(-1, MAP_SIZE+1):
		for x in range(-1, MAP_SIZE+1): 
			if get_cellv(Vector2i(x, y)) == TILE_IDX_UNSET:
				# Specal 1 thickness walls
				if get_cellv(Vector2i(x-1, y)) == TILE_IDX_FLOOR and get_cellv(Vector2i(x+1, y)) == TILE_IDX_FLOOR:
					set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(1, 1), 0)
					continue				
				if get_cellv(Vector2i(x, y-1)) == TILE_IDX_FLOOR and get_cellv(Vector2i(x, y+1)) == TILE_IDX_FLOOR:
					set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(2, 1), 0)
					continue		
									
				# Cardinal directions
				if get_cellv(Vector2i(x, y+1)) == TILE_IDX_FLOOR:
					set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(rng.randi_range(1, 4), 0), 0)
					if rng.randf() <= 0.2:
						_add_torch(x, y)
					continue
				if get_cellv(Vector2i(x, y-1)) == TILE_IDX_FLOOR:
					# "north" walls are a special case due to fake perspective
					if get_cellv(Vector2i(x-1, y)) == TILE_IDX_FLOOR:
						set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(0, 5), 0)
					elif get_cellv(Vector2i(x+1, y)) == TILE_IDX_FLOOR:
						set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(5, 5), 0)						
					else:
						set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(rng.randi_range(1, 4), 4), 0)
					continue
				if get_cellv(Vector2i(x+1, y)) == TILE_IDX_FLOOR:
					set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(0, rng.randi_range(0, 3)), 0)
					continue
				if get_cellv(Vector2i(x-1, y)) == TILE_IDX_FLOOR:
					set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(5, rng.randi_range(0, 3)), 0)
					continue			
								
				# Diagonals		
				if get_cellv(Vector2i(x+1, y-1)) == TILE_IDX_FLOOR:
					set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(0, 4), 0)
					continue
				if get_cellv(Vector2i(x-1, y-1)) == TILE_IDX_FLOOR:
					set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(5, 4), 0)
					continue
				if get_cellv(Vector2i(x+1, y+1)) == TILE_IDX_FLOOR:
					set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(0, 0), 0)
					continue
				if get_cellv(Vector2i(x-1, y+1)) == TILE_IDX_FLOOR:
					set_cellv(Vector2i(x, y), TILE_IDX_WALL, Vector2i(5, 0), 0)
			
func _add_torch(x, y):
	var torch_node: Node2D = TORCH_SCENE.instance()
	torch_node.position.x = x * GRID_SIZE
	torch_node.position.y = y * GRID_SIZE
	add_child(torch_node)
