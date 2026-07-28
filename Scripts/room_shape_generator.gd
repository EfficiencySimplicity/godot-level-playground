extends Area2D

@export var elements: ElementSet

func create_rect(min_size: Vector2i = Vector2i(4, 4), max_size: Vector2i = Vector2i(16, 16)) -> RectangleShape2D:
	var rect = RectangleShape2D.new()
	rect.size = Vector2(randi_range(min_size.x, max_size.x), randi_range(min_size.y, max_size.y))
	return rect

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
	
func place_element(element: ItemPlacer, map_stack: MapLayerStack):
	print("I'm going to try to place ", element.name)
	# creates the PlacementStack
	var stack = element.compile()
	# tests it on the given layers
	var ok_placements = stack.get_ok_placements_on(map_stack)
	if ok_placements.size() == 0:
		print("I couldn't place ", element.name)
		element.queue_free()
		return
		
	var pos = ok_placements.pick_random()
	print("I got the ok placement: ", pos)
	
	# Places it, accounting for all the offsets globally (using self),
	# and fills in the maps by reference
	element.place(self, stack, map_stack, pos)
	print("I placed the element")
	
func get_map_stack() -> MapLayerStack:
	# TODO: there must be a way to set the fill of the area2d...
	var layer = MapLayer.from_area2d(self, 64).inverted()
	var solids_layer = MapLayer.new(layer.size + Vector2i(2, 2), true)
	solids_layer.world_origin = layer.world_origin - Vector2(64, 64)
	layer.stamp_on(solids_layer, Placement.new(Vector2i(1, 1)))
	
	var must_be_empty_layer = MapLayer.new(solids_layer.size)
	
	var stack = MapLayerStack.from_layer_dict({"Solids": solids_layer, "MustBeEmpty": must_be_empty_layer})
	
	return stack

func generate():
	var shape = create_collision_shape(create_rect(Vector2i(4, 4), Vector2i(8, 8)))
	print("I created a collision shape with shape ", shape.shape.size)
	var shape_2 = extend_room(shape, Vector2i(4, 4), Vector2i(8, 8))
	print("I created another collision shape with shape ", shape_2.shape.size)
	add_shape(shape)
	print("I added the first shape; giving it size ", shape.shape.size)
	add_shape(shape_2)
	print("I added the second shape; giving it size ", shape_2.shape.size)

func _ready():
	generate()

	var stack = get_map_stack()

	for i in 25:
		place_element(elements.get_element(), stack)
