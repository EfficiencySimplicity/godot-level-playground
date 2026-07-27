extends Area2D

@export var elements: PlacementSet

func create_rect(min_size: Vector2i = Vector2i(4, 4), max_size: Vector2i = Vector2i(16, 16)) -> RectangleShape2D:
	var rect = RectangleShape2D.new()
	rect.size = Vector2(randi_range(min_size.x, max_size.x), randi_range(min_size.y, max_size.y))
	return rect
	
func extend_room(old_room: CollisionShape2D, min_size: Vector2i = Vector2i(4, 4), max_size: Vector2i = Vector2i(16, 16)) -> CollisionShape2D:

	var old_rect = old_room.shape
	var new_rect = create_rect(min_size, max_size)
	
	var side = randi_range(1, 4)

	# An extension the same size as the rect is odd
	if side % 2 == 0:
		new_rect.size.y = min(new_rect.size.y, old_rect.size.y)
	else:
		new_rect.size.x = min(new_rect.size.x, old_rect.size.x)
	
	var new_room = create_collision_shape(new_rect)
	
	if side == 1:# top
		new_room.position.x = old_room.position.x
		new_room.position.y = old_room.position.y - new_rect.size.y
	if side == 2:# right
		new_room.position.x = old_room.position.x + old_rect.size.x
		new_room.position.y = old_room.position.y
	if side == 3:# bottom
		new_room.position.x = old_room.position.x
		new_room.position.y = old_room.position.y + old_rect.size.y
	if side == 4:# left
		new_room.position.x = old_room.position.x - new_rect.size.x
		new_room.position.y = old_room.position.y
		
	return new_room

func create_collision_shape(rect: RectangleShape2D):
	var shape = CollisionShape2D.new()
	shape.shape = rect
	return shape

func add_shape(shape: CollisionShape2D):
	# convert from block scale to pixel scale
	shape.position *= 64
	shape.shape.size *= 64
	shape.position += shape.shape.size / 2
	add_child(shape)
	
func place_element(element: ItemPlacer, map_stack: MapLayerStack):
	print("I'm going to try to place ", element.name)
	#var must_be_empty_layer = MapLayer.with_size(solids_layer.size, false)
	
	# creates the PlacementStack
	var stack = element.compile()
	print("Size: ", stack.size, ", world origin: ", stack.world_origin)
	# tests it on the given layers
	var ok_placements = stack.get_ok_placements_on(map_stack)
	print("I got the ok placements:")
	print(ok_placements)
	if ok_placements.size() == 0:
		print("Couldn't place ", element.name)
		element.queue_free()
		return
		
	var pos = ok_placements.pick_random()
	print("I got the ok placement: ", pos)
	
	# Places it, accounting for all the offsets globally (using self),
	# and fills in the maps by reference
	element.place(self, stack, map_stack, pos)
	print("I placed the element")
	
func get_solids_layer():
	print("I'm getting the solids layer")
	# TODO: there must be a way to set the fill of the area2d...
	var layer = MapLayer.from_area2d(self, 64).inverted()
	print("I got the unbordered area:")
	print(layer)
	var bordered = MapLayer.with_size(layer.size + Vector2i(2, 2), true)
	bordered.world_origin = layer.world_origin - Vector2(64, 64)
	print("I got the border area:")
	print(bordered)
	layer.stamp_on(bordered, Vector2i(1, 1))
	print("I stamped inside the border area:")
	print(bordered)
	return bordered
	
func get_must_be_empty_layer(solids_layer: MapLayer):
	print("I'm getting the must-be-empty layer")
	return MapLayer.with_size(solids_layer.size)

func generate():
	print("I am generating a room")
	var shape = create_collision_shape(create_rect())
	print("I created a collision shape with shape ", shape.shape.size)
	var shape_2 = extend_room(shape)
	print("I created another collision shape with shape ", shape_2.shape.size)
	add_shape(shape)
	print("I added the first shape; giving it size ", shape.shape.size)
	add_shape(shape_2)
	print("I added the second shape; giving it size ", shape_2.shape.size)

func _ready():
	generate()
	var solids_layer = get_solids_layer()
	print("I got the solids layer:")
	print(solids_layer)
	var must_be_empty_layer = get_must_be_empty_layer(solids_layer)
	print("I got the must-be-empty layer:")
	print(must_be_empty_layer)
	var stack = MapLayerStack.from_layer_dict({"Solids": solids_layer, "MustBeEmpty": must_be_empty_layer})
	print("I put it in a stack:")
	print(stack)
	for i in 25:
		place_element(elements.get_element(), stack)
	print("I generated the room")
	var map_layer = MapLayer.from_area2d(self)
	print("I got the room's MapLayer, with size", map_layer.size, ":")
	print(map_layer)
	var layer_2 = MapLayer.with_size(map_layer.size + Vector2i(2, 2))
	map_layer.place_on(layer_2, Vector2i(1,1))
	print(layer_2)
