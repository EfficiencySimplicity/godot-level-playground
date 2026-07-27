class_name PlacementStack

# could store size and world bounds as a whole thing forever...

var layers: Array[PlacementLayer]

# it would be better to store smaller maps and offsets,
# but really, how much better?
var world_origin: Vector2
var size: Vector2i

static func from_placement_layers(_layers: Array[PlacementLayer]):
	var stack = PlacementStack.new()
	stack.layers = _layers
	var array: Array[MapLayer]
	array.assign(_layers)
	var bounds = MapLayer.get_group_bounds(array)
	
	stack.world_origin = bounds.position
	stack.size = Vector2i(bounds.size / _layers[0].cell_size)
	
	return stack
	
#
#static func from_area_2ds(_solids: Area2D, _must_be_solids: Area2D, cell_size: int = 64) -> PlacementStack:
	#var stack = PlacementStack.new()
	#stack.solids = MapLayer.from_area2d(_solids, cell_size) if _solids != null else null
	#stack.must_be_solids =  MapLayer.from_area2d(_must_be_solids, cell_size) if _must_be_solids != null else null
	#
	#var all_layers: Array[MapLayer] = []
	#if stack.solids != null:
		#all_layers.append(stack.solids)
	#if stack.must_be_solids != null:
		#all_layers.append(stack.must_be_solids)
	#var group_bounds = MapLayer.get_group_bounds(all_layers)
	#
	#stack.world_origin = group_bounds.position
	#stack.size = Vector2i(group_bounds.size / cell_size)
	#
	#return stack
	
func get_match_position(pos, layer) -> Vector2i:
	return pos + get_cell_offset(layer)
	
func get_cell_offset(layer) -> Vector2i:
	return Vector2i((layer.world_origin - world_origin) / layer.cell_size)

func get_ok_placements_on(other: MapLayerStack) -> Array[Vector2i]:
	var ok_positions: Array[Vector2i] = []
	for y in other.size.y - size.y:
		for x in other.size.x - size.x:
			if placement_is_ok(other, Vector2i(x, y)):
				ok_positions.append(Vector2i(x, y))
	return ok_positions
	
func placement_is_ok(other: MapLayerStack, pos: Vector2i):
	for layer in layers:
		if !layer.test_placeable(other, get_match_position(pos, layer)):
			return false
	return true
	
func place(other: MapLayerStack, pos: Vector2i):
	for layer in layers:
		layer.place(other, get_match_position(pos, layer))
