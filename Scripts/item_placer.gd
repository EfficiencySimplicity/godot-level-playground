class_name ItemPlacer extends Node2D

@export var _solids: Area2D
@export var _must_be_solids: Area2D
@export var _must_be_empty: Area2D

func compile() -> PlacementStack:
	var layers: Array[PlacementLayer]
	
	if _solids != null:
		var _solids_layer = MapLayer.from_area2d(_solids)
		var solids_layer = PlacementLayer.new(_solids_layer, 
			{"Solids": _solids_layer.doesnt_collide, "MustBeEmpty": _solids_layer.doesnt_collide},
			{"Solids": _solids_layer.place_on})
		layers.append(solids_layer)
		
	if _must_be_solids != null:
		var _must_be_solids_layer = MapLayer.from_area2d(_must_be_solids)
		var must_be_solids_layer = PlacementLayer.new(_must_be_solids_layer, 
			{"Solids": _must_be_solids_layer.overlaps})
		layers.append(must_be_solids_layer)
		
	if _must_be_empty != null:
		var _must_be_empty_layer = MapLayer.from_area2d(_must_be_empty)
		var must_be_empty_layer = PlacementLayer.new(_must_be_empty_layer, 
			{"Solids": _must_be_empty_layer.doesnt_collide},
			{"MustBeEmpty": _must_be_empty_layer.place_on})
		layers.append(must_be_empty_layer)
	
	return PlacementStack.from_placement_layers(layers)
			
func place(parent: Node2D, stack: PlacementStack, dest: MapLayerStack, pos: Vector2i):
	print("Placing the item at ", pos)
	var world_position = dest.cell_to_world(pos)
	print("World position of the place to place it at: ", world_position)
	# I don't understand this so far.
	world_position -= (stack.world_origin - global_position)
	print("World position considering the item's offset of ", stack.world_origin - global_position, ": ", world_position)
	parent.add_child(self)
	global_position = world_position
	stack.place(dest, pos)
