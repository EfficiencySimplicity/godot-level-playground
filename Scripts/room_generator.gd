extends Area2D

@export var elements: ElementSet
@export var gen_on_ready: bool = false

var stack: MapLayerStack

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
	
	var side = randi_range(0, 3)

	# An extension the same size as the rect is odd
	if side % 2 != 0:
		new_rect.size.y = min(new_rect.size.y, old_rect.size.y)
	else:
		new_rect.size.x = min(new_rect.size.x, old_rect.size.x)
	
	var new_room = create_collision_shape(new_rect)
	
	if side == Placement.Side.Up:
		new_room.position.x = old_room.position.x
		new_room.position.y = old_room.position.y - new_rect.size.y
	if side == Placement.Side.Right:
		new_room.position.x = old_room.position.x + old_rect.size.x
		new_room.position.y = old_room.position.y
	if side == Placement.Side.Down:
		new_room.position.x = old_room.position.x
		new_room.position.y = old_room.position.y + old_rect.size.y
	if side == Placement.Side.Left:
		new_room.position.x = old_room.position.x - new_rect.size.x
		new_room.position.y = old_room.position.y
		
	return new_room
	
func place_element(element: ItemPlacer):
	# creates the PlacementStack
	element.attempt_place(self, stack)
	
func get_solids_layer() -> MapLayer:
	# TODO: there must be a way to set the fill of the area2d...
	var layer = MapLayer.from_area2d(self, 64).inverted()
	var solids_layer = MapLayer.new(layer.size + Vector2i(2, 2), true)
	solids_layer.world_bounds = layer.world_bounds.grow(64)
	layer.stamp_on(solids_layer, Placement.new(Vector2i(1, 1)))
	
	return solids_layer
	
func get_map_stack():
	var solids_layer = get_solids_layer()
	
	var must_be_empty_layer = MapLayer.new(solids_layer.size)
	
	stack = MapLayerStack.from_layer_dict({"Solids": solids_layer, "MustBeEmpty": must_be_empty_layer})
	
func generate_room_shape():
	var shape = create_collision_shape(create_rect(Vector2i(4, 4), Vector2i(8, 8)))
	print("I created a collision shape with shape ", shape.shape.size)
	var shape_2 = extend_room(shape, Vector2i(4, 4), Vector2i(8, 8))
	print("I created another collision shape with shape ", shape_2.shape.size)
	add_shape(shape)
	print("I added the first shape; giving it size ", shape.shape.size)
	add_shape(shape_2)
	print("I added the second shape; giving it size ", shape_2.shape.size)
	
	get_map_stack()
	
func stamp_room_shape():
	var solids = get_solids_layer()
	
	solids.stamp_on_tilemap(get_parent().find_child("Floor"), 0, Vector2i(-1, -1), Vector2i(0, 0))
	solids.stamp_on_tilemap(get_parent().find_child("Walls"), 0, Vector2i(1, 0), Vector2i(-1, -1))
	
func generate_items():
	for i in 25:
		place_element(elements.get_element())

func generate():
	generate_room_shape()
	stamp_room_shape()
	generate_items()
	
func _ready():
	if gen_on_ready:
		generate()
