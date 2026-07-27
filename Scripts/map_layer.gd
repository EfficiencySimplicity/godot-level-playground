class_name MapLayer
## This class represents a grid layer to perform various tests on.[br]
## Such as 'oh, this cell must be solid', 'this one must always be empty';[br]
## et cetera!

## The data of the MapLayer
var data: BitMap
## The width and height of the MapLayer
var size: Vector2i
## The position of the top left corner of the MapLayer in world space, for placing things easily
var world_origin: Vector2
## The size in world space of each cell in the MapLayer
var cell_size: int = 64

## Sets the size of the MapLayer, optionally filling it with a value.[br]
## Returns the MapLayer for easy piping
static func with_size(_size: Vector2i, fill: bool = false) -> MapLayer:
	var map_layer = MapLayer.new()
	map_layer.size = _size
	map_layer.data = BitMap.new()
	map_layer.data.create(_size)
	map_layer.data.set_bit_rect(Rect2i(Vector2i(0, 0), _size), fill)
	return map_layer

## Creates a MapLayer from a bounding rect (world space
static func from_rect(rect: Rect2, _cell_size: int = 64, fill: bool = false) -> MapLayer:
	var map_layer = MapLayer.with_size(rect.size / _cell_size, fill)
	map_layer.world_origin = rect.position
	return map_layer
	
static func from_layers(layers: Array) -> MapLayer:
	var bounds = get_group_bounds(layers)
	var _cell_size = layers[0].cell_size
	
	var map_layer = MapLayer.with_size(bounds.size / _cell_size)
	map_layer.world_origin = bounds.position
	map_layer.cell_size = _cell_size
	
	for layer in layers:
		layer.place_on(map_layer, Placement.new((layer.world_origin - bounds.position) / _cell_size))
	
	return map_layer
	
static func get_group_bounds(layers: Array[MapLayer]) -> Rect2:
	var rect : Rect2 = Rect2()
	for layer in layers:
		rect = rect.merge(layer.get_world_rect())
	return rect
	
# This could be a Rect2i...
func get_world_rect() -> Rect2:
	return Rect2(world_origin, size * cell_size)
	
## Returns the top left corner of the specified cell in world space
func cell_to_world(pos: Vector2i):
	return world_origin + Vector2(pos * cell_size)

## Gets an value from the MapLayer
func g(pos: Vector2i) -> bool:
	return data.get_bitv(pos)

## Sets a value in the MapLayer
func s(pos: Vector2i, value: bool):
	data.set_bitv(pos, value)
	
## Stamps this MapLayer on another, overwriting all values within its area
func stamp_on(other: MapLayer, pos: Placement):
	for y in range(size.y):
		for x in range(size.x):
			# we can just add the two since down is +y in GD
			# of course if up was +y the whole room would be
			# in quadrant I so it doesn't matter anyway, right?
			other.s(pos.map_vector2i(Vector2i(x, y)), g(Vector2i(x, y)))
			
## Places this MapLayer on another, only writing down 1s
func place_on(other: MapLayer, pos: Placement):
	for y in range(size.y):
		for x in range(size.x):
			# we can just add the two since down is +y in GD
			# of course if up was +y the whole room would be
			# in quadrant I so it doesn't matter anyway, right?
			if g(Vector2i(x, y)):
				other.s(pos.map_vector2i(Vector2i(x, y)), true)
			
## Returns true if the MapLayers contain equal values starting at the specified position
func matches(other: MapLayer, pos: Placement) -> bool:
	for y in range(size.y):
		for x in range(size.x):
			# we can just add the two since down is +y in GD
			# of course if up was +y the whole room would be
			# in quadrant I so it doesn't matter anyway, right?
			if other.g(pos.map_vector2i(Vector2i(x, y))) != g(Vector2i(x, y)):
				return false
	return true
	
## Returns true if the MapLayers have at least 1 cell where they're both true
func collides(other: MapLayer, pos: Placement) -> bool:
	for y in range(size.y):
		for x in range(size.x):
			if other.g(pos.map_vector2i(Vector2i(x, y))) and g(Vector2i(x, y)):
				return true
	return false
	
## Returns true if the MapLayers do not collide with any 1s
func doesnt_collide(other: MapLayer, pos: Placement) -> bool:
	return !collides(other, pos)
	
## Returns true if wherever the MapLayer is true, the other is also
func overlaps(other: MapLayer, pos: Placement) -> bool:
	for y in range(size.y):
		for x in range(size.x):
			if g(Vector2i(x, y)) and not other.g(pos.map_vector2i(Vector2i(x, y))):
					return false
	return true
	
## The MapLayer will be 0 (false) wherever it is outside the room
static func from_area2d(area: Area2D, _cell_size: int = 64) -> MapLayer:
	if area == null:
		return null
		
	var minis: Array[MapLayer] = []
	
	var children = area.get_children().filter(func(x): return x is CollisionShape2D and x.shape != null)
	
	if children.size() == 0:
		return null
		
	for shape in children:
		minis.append(MapLayer.from_collision_shape(shape, _cell_size))
			
	return MapLayer.from_layers(minis)

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
	new_layer.world_origin = world_origin
	
	return new_layer
	

# The cell size could be a custom Node Type; say... PlacementLayer? could be different from MapLayer or something
static func from_collision_shape(shape: CollisionShape2D, _cell_size: int) -> MapLayer:
	var bounding_rect = Rect2i(Vector2i(shape.global_position - shape.shape.size / 2), shape.shape.size)
	return MapLayer.from_rect(bounding_rect, _cell_size, 1)
	
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
