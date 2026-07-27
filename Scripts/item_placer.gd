class_name ItemPlacer extends Node2D

@export var _solids: Area2D
@export var _must_be_solids: Area2D
@export var _must_be_empty: Area2D

# TODO: the whole placement thing in a single loop! so this obj never exposes its placement
# and it self-deletes, maybe returning a bool if successful.

func compile() -> PlacementStack:
	var layers: Array[PlacementLayer]
	
	var _solids_layer = MapLayer.from_area2d(_solids)
	if _solids_layer != null:
		var solids_layer = PlacementLayer.new(_solids_layer, 
			{"Solids": _solids_layer.doesnt_collide, "MustBeEmpty": _solids_layer.doesnt_collide},
			{"Solids": _solids_layer.place_on})
		layers.append(solids_layer)
		
	var _must_be_solids_layer = MapLayer.from_area2d(_must_be_solids)
	if _must_be_solids_layer != null:
		var must_be_solids_layer = PlacementLayer.new(_must_be_solids_layer, 
			{"Solids": _must_be_solids_layer.overlaps})
		layers.append(must_be_solids_layer)
		
	var _must_be_empty_layer = MapLayer.from_area2d(_must_be_empty)
	if _must_be_empty_layer != null:
		var must_be_empty_layer = PlacementLayer.new(_must_be_empty_layer, 
			{"Solids": _must_be_empty_layer.doesnt_collide},
			{"MustBeEmpty": _must_be_empty_layer.place_on})
		layers.append(must_be_empty_layer)
	
	return PlacementStack.from_placement_layers(layers)
			
func place(parent: Node2D, stack: PlacementStack, dest: MapLayerStack, pos: Placement):
	# This is where the top left corner of the PlacementStack is in world space
	var world_position = dest.cell_to_world(pos.position)
	# This is how far away the stack is from me in world space
	var stack_offset = (stack.world_origin - global_position)
	# we add this, rotated correctly to the world position
	var my_position = world_position - Vector2(pos.map_vector2i(stack_offset))
	# get the center of that cell
	my_position += Vector2(dest.layers.values()[0].cell_size / 2, dest.layers.values()[0].cell_size / 2)
	# go to the proper corner and place!
	my_position += Vector2(pos.map_vector2i(Vector2i(-dest.layers.values()[0].cell_size / 2, -dest.layers.values()[0].cell_size / 2)))
	
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
	rotation_degrees = pos.side * 90 - 90
	stack.place(dest, pos)
