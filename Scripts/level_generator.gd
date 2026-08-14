extends Node2D

@export var num_rooms: int = 16
@export var room_gap: int = 50
@export var doors_per_room_range: Vector2i

@export var tile_map_layers: Dictionary[String, TileMapLayer]

@onready var room_generator = preload("res://Scenes/room_generator.tscn")
@onready var door = preload("res://Scenes/door.tscn")

#var global_solids: MapLayer
var door_portals: Array[Door]

func get_next_move_orientation(object: Node2D):
	var obj_orientation = Orientation.from_object(object)
	var grid_placement  = obj_orientation.to_placement()
	var door_there = door_portals.find_custom(func(x): return Orientation.from_object(x).to_placement().cell_center() == grid_placement.cell_center())
	
	if door_there == -1:
		# no door, just your position plus the new vector
		return obj_orientation.move_forwards(64)

	else:
		print("Was on a door; placement is ", grid_placement, " and door is ", Orientation.from_object(door_portals.get(door_there)).to_placement())
		return door_portals.get(door_there).door_transform(obj_orientation).move_forwards(64)


func _ready():
	var grid_width = int(floor(sqrt(num_rooms)))
	var rooms = []
	
	for i in num_rooms:
		var x = i % grid_width
		var y = floor(i / grid_width)
		x *= room_gap * 64
		y *= room_gap * 64
		
		var room = room_generator.instantiate()
		room.global_position = Vector2(x, y)
		add_child(room)
	
		rooms.append(room)
		
	rooms.map(func(x): x.generate_room_shape())
	rooms.map(func(x): x.stamp_room_shape())
	connect_doors(rooms, place_doors(rooms))
	print("Doors connected!")
	rooms.map(func(x): x.generate_items())
	rooms.map(func(x): x.orient_viewport())
	
func place_doors(rooms):
	var doors: Array[DoorPlacer] = []
	
	rooms.map(func(x):
		var num_doors = randi_range(doors_per_room_range.x, doors_per_room_range.y)
		
		# If we are on the last room, make sure we end up with an even number
		# of doors in the world after this
		if x == rooms[-1]:
			if (doors.size() + num_doors) % 2 != 0:
				num_doors += 1
				
		for i in num_doors:
			var door_obj = door.instantiate()
			assert(x.place_element(door_obj), "A door could not be placed!!!")
			
			doors.append(door_obj)
			x.own_door(door_obj.actual_door)
	)
	
	return doors

# 1-door rooms, an abundance of such, could cause problems...
func connect_doors(rooms, doors: Array[DoorPlacer]):
	var remaining_rooms = rooms.duplicate()
	var available_doors = []

	remaining_rooms.erase(rooms[0])
	available_doors.append_array(get_doors_of_room(rooms[0], doors))
	
	while remaining_rooms.size() > 0:
		var room_to_connect
		var other_doors
		
		# Make sure we don't deadend ourselves
		# this could technically go on forever, TODO
		while true:
			room_to_connect = remaining_rooms.pick_random()
			other_doors = get_doors_of_room(room_to_connect, doors)
			
			if other_doors.size() + available_doors.size() - 2 > 0:
				break
			
		var door_to_connect_to = other_doors.pick_random()
		
		var door_to_connect = available_doors.pick_random()
		
		door_to_connect.actual_door.connect_door(door_to_connect_to.actual_door)
		door_portals.append(door_to_connect.actual_door)
		door_portals.append(door_to_connect_to.actual_door)
		
		other_doors.erase(door_to_connect_to)
		available_doors.erase(door_to_connect)
		
		available_doors.append_array(other_doors)		
		remaining_rooms.erase(room_to_connect)
		
	while available_doors.size() > 0:
		var door_a = available_doors.pick_random()
		available_doors.erase(door_a)
		var door_b = available_doors.pick_random()
		available_doors.erase(door_b)
		
		door_portals.append(door_a.actual_door)
		door_portals.append(door_b.actual_door)
		
		door_a.actual_door.connect_door(door_b.actual_door)
		
		
	
func get_doors_of_room(room, doors):
	return doors.filter(func(x): return x.get_parent() == room)
