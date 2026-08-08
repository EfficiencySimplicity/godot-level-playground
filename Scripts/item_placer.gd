class_name ItemPlacer extends Node2D

@export var _solids: CollisionObject2D
@export var _must_be_solids: CollisionObject2D
@export var _must_be_empty: CollisionObject2D

@export var tiles: Array[TileStamper]

# TODO: the whole placement thing in a single loop! so this obj never exposes its placement
# and it self-deletes, maybe returning a bool if successful.

func attempt_place(parent: Node2D, map_stack: MapLayerStack) -> bool:
	var stack = _compile()

	var pos = get_non_room_blocking_placement(stack, map_stack, stack.get_ok_placements_on(map_stack))
	if pos == null:
		queue_free()
		return false
		
	
	# This is where the top left corner of the PlacementStack is in world space
	var world_position = map_stack.cell_to_world(pos.position)
	# This is how far away the stack is from me in world space
	var stack_offset = (stack.world_bounds.position - global_position)
	# we add this, rotated correctly to the world position
	var my_position = world_position - Vector2(pos.map_vector2i(stack_offset))
	# get the center of that cell
	my_position += Vector2(map_stack.layers.values()[0].cell_size / 2, map_stack.layers.values()[0].cell_size / 2)
	# go to the proper corner and place!
	my_position += Vector2(pos.map_vector2i(Vector2i(-map_stack.layers.values()[0].cell_size / 2, -map_stack.layers.values()[0].cell_size / 2)))
	
	# if this is confusing, imagine a stack, and associated sprites,
	# that starts 1 to the right and 1 down from the object origin
	# (weird, but ok)
	
	# so the stack_offset is (64, 64)
	
	# also, say the world dest in the map is (100, 200)
	
	# so the stack needs to be at 100, 200
	# so the world position of the object needs to be at (100, 200) - (64, 64),
	# or (36, 136)

	parent.add_child(self)
	global_position = my_position
	rotation_degrees = pos.side * 90
	stack.place(map_stack, pos)
	
	on_place(stack, map_stack, pos)
	
	for layer in tiles:
		layer.stamp(parent.get_parent().tile_map_layers[layer.dest_name])
		
	return true

func get_non_room_blocking_placement(stack: PlacementStack, map_stack: MapLayerStack, ok_placements: Array[Placement]):
	while !ok_placements.is_empty():
		var pos = ok_placements.pick_random()
		ok_placements.remove_at(ok_placements.find(pos))
	
		# Places it, accounting for all the offsets globally (using self),
		# and fills in the maps by reference
		# https://www.reddit.com/r/godot/comments/cgw8w8/how_to_check_if_a_key_exists_in_a_dictionary_in/
		if stack.layers.has("Solids"):
			var test_dest = map_stack.layers["Solids"].copy()
			stack.layers["Solids"].old_layer.place_on(test_dest, stack.get_match_position(pos, stack.layers["Solids"]))
			if test_dest.is_whole():
				return pos
		else:
			return pos
			
	return null
	
	
func _compile() -> PlacementStack:
	var layers: Dictionary[String, PlacementLayer]
	
	var _solids_layer = MapLayer.from_shapes2d(_solids)
	if _solids_layer != null:
		var solids_layer = PlacementLayer.new(_solids_layer, 
			{"Solids": _solids_layer.doesnt_collide, "MustBeEmpty": _solids_layer.doesnt_collide},
			{"Solids": _solids_layer.place_on})
		layers["Solids"] = solids_layer
		
	var _must_be_solids_layer = MapLayer.from_shapes2d(_must_be_solids)
	if _must_be_solids_layer != null:
		var must_be_solids_layer = PlacementLayer.new(_must_be_solids_layer, 
			{"Solids": _must_be_solids_layer.overlaps})
		layers["MustBeSolids"] = must_be_solids_layer
		
	var _must_be_empty_layer = MapLayer.from_shapes2d(_must_be_empty)
	if _must_be_empty_layer != null:
		var must_be_empty_layer = PlacementLayer.new(_must_be_empty_layer, 
			{"Solids": _must_be_empty_layer.doesnt_collide},
			{"MustBeEmpty": _must_be_empty_layer.place_on})
		layers["MustBeEmpty"] = must_be_empty_layer
	
	return PlacementStack.from_placement_layers(layers)

func on_place(stack, map_stack, pos):
	pass
