class_name MapLayer
## This class represents a grid layer to perform various tests on.[br]
## Such as 'oh, this cell must be solid', 'this one must always be empty';[br]
## et cetera!

## The data of the MapLayer
var data: BitMap
## The width and height of the MapLayer
var size: Vector2i
## The position of the top left corner of the MapLayer in world space, for placing things easily
var world_bounds: Rect2
## The size in world space of each cell in the MapLayer
var cell_size: int = 64

func _init(_size: Vector2i = Vector2i(1, 1), fill: bool = false):
	size = _size
	data = BitMap.new()
	data.create(_size)
	data.set_bit_rect(Rect2i(Vector2i(0, 0), _size), fill)
	
func copy() -> MapLayer:
	var m = MapLayer.new(Vector2(1, 1))
	m.data = data.duplicate()
	m.size = size
	m.world_bounds = world_bounds
	m.cell_size = cell_size
	return m

## Creates a MapLayer from a bounding rect (world space)
static func from_rect(rect: Rect2, _cell_size: int = 64, fill: bool = false) -> MapLayer:
	var map_layer = MapLayer.new(rect.size / _cell_size, fill)
	map_layer.world_bounds = rect
	return map_layer
	
static func from_layers(layers: Array, stamp: bool = true) -> MapLayer:
	var bounds = get_group_bounds(layers)
	var _cell_size = layers[0].cell_size
	
	var map_layer = MapLayer.new(bounds.size / _cell_size)
	map_layer.world_bounds = bounds
	map_layer.cell_size = _cell_size
	
	if stamp:
		for layer in layers:
			layer.place_on(map_layer, Placement.new((layer.world_bounds.position - bounds.position) / _cell_size))
	
	return map_layer
	
static func get_group_bounds(layers: Array) -> Rect2:
	return layers.reduce(func(rect, layer): return rect.merge(layer.world_bounds), layers[0].world_bounds)
	
# The cell size could be a custom Node Type; say... PlacementLayer? could be different from MapLayer or something
static func from_collision_shape(shape: CollisionShape2D, _cell_size: int) -> MapLayer:
	var bounding_rect = Rect2i(Vector2i(shape.global_position - shape.shape.size / 2), shape.shape.size)
	return MapLayer.from_rect(bounding_rect, _cell_size, 1)
	
## The MapLayer will be 0 (false) wherever it is outside the room
static func from_shapes2d(collider: CollisionObject2D, _cell_size: int = 64) -> MapLayer:
	if collider == null:
		return null

	var shapes = collider.find_children("*", "CollisionShape2D", true, false).filter(func(x): return x.shape != null)
	
	if shapes.is_empty():
		return null

	return MapLayer.from_layers(
		shapes.map(func(shape): return MapLayer.from_collision_shape(shape, _cell_size))
	)

## Gets an value from the MapLayer
func g(pos: Vector2i) -> bool:
	return data.get_bitv(pos)

## Sets a value in the MapLayer
func s(pos: Vector2i, value: bool):
	data.set_bitv(pos, value)

## Returns the top left corner of the specified cell in world space
func cell_to_world(pos: Vector2i):
	return world_bounds.position + Vector2(pos * cell_size)
	
## gets where this MapLayer's top left corner cell sits on another in its cell space
func position_on(other: MapLayer) -> Placement:
	return Placement.new((world_bounds.position - other.world_bounds.position) / cell_size)
	
## Stamps this MapLayer on another, overwriting all values within its area
func stamp_on(other: MapLayer, pos: Placement = null):
	if pos == null: pos = position_on(other)
	iter_cells(func(xy): other.s(pos.map_vector2i(xy), g(xy)))
			
## Places this MapLayer on another, only writing down 1s
func place_on(other: MapLayer, pos: Placement = null):
	if pos == null: pos = position_on(other)
	iter_cells(
		func(xy):
			if g(xy):
				other.s(pos.map_vector2i(xy), true)
	)

## Returns true if the MapLayers contain equal values starting at the specified position
func matches(other: MapLayer, pos: Placement = null) -> bool:
	if pos == null: pos = position_on(other)
	return iter_cells(
		(func(xy):
			if other.g(pos.map_vector2i(xy)) != g(xy):
				return false),
		true
	)
	
## Returns true if the MapLayers have at least 1 cell where they're both true
func collides(other: MapLayer, pos: Placement = null) -> bool:
	if pos == null: pos = position_on(other)
	return iter_cells(
		(func(xy): 
			if other.g(pos.map_vector2i(xy)) and g(xy):
				return true),
		false
	)
	
## Returns true if the MapLayers do not collide with any 1s
func doesnt_collide(other: MapLayer, pos: Placement = null) -> bool:
	if pos == null: pos = position_on(other)
	return !collides(other, pos)
	
## Returns true if wherever the MapLayer is true, the other is also
func overlaps(other: MapLayer, pos: Placement = null) -> bool:
	if pos == null: pos = position_on(other)
	return iter_cells(
		(func(xy):
			if g(xy) and not other.g(pos.map_vector2i(xy)):
				return false),
		true
	)
	

func inverted() -> MapLayer:
	var new_data = BitMap.new()
	new_data.create(size)
	for y in size.y:
		for x in size.x:
			new_data.set_bit(x, y, !data.get_bit(x, y))
			
	var new_layer = MapLayer.new()
	new_layer.data = new_data
	new_layer.size = size
	new_layer.cell_size = cell_size
	new_layer.world_bounds = world_bounds
	
	return new_layer

func bordered(value: bool = false) -> MapLayer:
	var expanded = MapLayer.new(size + Vector2i(2, 2), value)
	expanded.world_bounds = world_bounds.grow(cell_size)
	stamp_on(expanded, Placement.new(Vector2i(1, 1)))
	return expanded

func place_on_tilemap(tilemap: TileMapLayer, source_id: int = -1, tile_pos: Vector2i = Vector2i(0, 0)):
	# https://www.reddit.com/r/godot/comments/gb31yp/get_tile_index_for_use_in_tilemapset_cellx_y_tile/
	iter_cells(
		func(xy):
			if !g(xy):
				return
			var cell = tilemap.local_to_map(world_bounds.position + Vector2(xy * Vector2i(cell_size, cell_size)))
			tilemap.set_cell(cell, source_id, tile_pos)
	)
	
func stamp_on_tilemap(tilemap: TileMapLayer, source_id: int = -1, true_tile_pos: Vector2i = Vector2i(0, 0), false_tile_pos: Vector2i = Vector2i(-1, -1)):
	# https://www.reddit.com/r/godot/comments/gb31yp/get_tile_index_for_use_in_tilemapset_cellx_y_tile/
	iter_cells(
		func(xy):
			var cell = tilemap.local_to_map(world_bounds.position + Vector2(xy * Vector2i(cell_size, cell_size)))
			tilemap.set_cell(cell, source_id, true_tile_pos if g(xy) else false_tile_pos)
	)
	
## Tests that all of the cells with the specified value are a single continuous area.
func is_whole(value: bool = false):
	var total_empty_cells = data.get_true_bit_count()
	if !value: total_empty_cells = (size.x * size.y) - total_empty_cells

	var hit_positions: Array[Vector2i] = []

	hit_positions.append(iter_cells(
		(func(xy):
			if g(xy) == value:
				return xy)
				))
	var i = 0
	while i < hit_positions.size():
		var pos = hit_positions[i]
		for side in 4:
			var new_point = Placement.new(pos, side).map_vector2i(Vector2i.RIGHT).clamp(Vector2i.ZERO, size-Vector2i.ONE)
			if g(new_point) == value:
				if new_point not in hit_positions:
					hit_positions.append(new_point)
		i += 1
		
	return hit_positions.size() == total_empty_cells
		
func iter_cells(f: Callable, default = null):
	for y in size.y:
		for x in size.x:
			var v = f.call(Vector2i(x, y))
			if v != null:
				return v
	if default != null:
		return default
	
	
# https://forum.godotengine.org/t/how-to-make-a-class-printable/25991/4
func _to_string() -> String:
	var lines = Array()
	for y in range(size.y):
		var line = ""
		for x in range(size.x):
			line += "1" if g(Vector2i(x, y)) else "0"
		line += "\n"
		lines.append(line)
	return "".join(lines)
