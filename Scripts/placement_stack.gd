class_name PlacementStack

# could store size and world bounds as a whole thing forever...

var layers: Dictionary[String, PlacementLayer]

# it would be better to store smaller maps and offsets,
# but really, how much better?
var world_origin: Vector2
var size: Vector2i

static func from_placement_layers(_layers: Dictionary[String, PlacementLayer]):
	var stack = PlacementStack.new()
	stack.layers = _layers
	var _array: Array[MapLayer] = []
	_array.assign(_layers.values().map(func(x): return x.old_layer))
	var bounds = MapLayer.get_group_bounds(_array)
	
	stack.world_origin = bounds.position
	stack.size = Vector2i(bounds.size / _layers.values()[0].cell_size)
	
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
	
## Takes in the placement of the stack and tells you
## the placement of the individual layer, which has the
## same rotation but is shifted according to the offset / rotation
func get_match_position(pos: Placement, layer) -> Placement:
	return Placement.new(pos.map_vector2i(get_cell_offset(layer)), pos.side)
	
## Returns the untranslated offset in world space of this layer
## relative to the origin of the stack
func get_cell_offset(layer) -> Vector2i:
	return Vector2i((layer.world_origin - world_origin) / layer.cell_size)

## Tests all positions and orientations and returns an array
## of everywhere this stack could be placed.
func get_ok_placements_on(other: MapLayerStack) -> Array[Placement]:
	var ok_positions: Array[Placement] = []
	for side in 5:
		
		# TODO: via clever algebra, distill all these side pickers,
		# perhaps even globally, into a simple formula
		var x_start: int
		if side == 0 or side == 3:
			x_start = 0
		elif side == 1:
			x_start = size.y
		elif side == 2:
			x_start = size.x
			
		var x_end: int
		if side == 0:
			x_end = other.size.x - size.x
		elif side == 1 or side == 3:
			x_end = other.size.x - size.y
		elif side == 2:
			x_end = other.size.x
			
		var y_start: int
		if side == 0 or side == 1:
			y_start = 0
		elif side == 2:
			y_start = size.y
		elif side == 3:
			y_start = size.x
			
		var y_end: int
		if side == 0:
			y_end = other.size.y - size.y
		elif side == 1:
			y_end = other.size.y - size.x
		elif side == 2 or side == 3:
			y_end = other.size.y

		for y in range(y_start, y_end):
			for x in range(x_start, x_end):
				if placement_is_ok(other, Placement.new(Vector2i(x, y), side)):
					ok_positions.append(Placement.new(Vector2i(x, y), side))
	return ok_positions
	
func placement_is_ok(other: MapLayerStack, pos: Placement):
	for layer in layers.values():
		if !layer.test_placeable(other, get_match_position(pos, layer)):
			return false
	return true
	
func place(other: MapLayerStack, pos: Placement):
	for layer in layers.values():
		layer.place(other, get_match_position(pos, layer))
