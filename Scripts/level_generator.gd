extends Node2D

@export var num_rooms: int = 16
@export var room_gap: int = 50
@export var doors_per_room: int = 2

@onready var room_generator = preload("res://Scenes/room_generator.tscn")
@onready var door = preload("res://Scenes/door.tscn")

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
	rooms.map(func(x):
		for i in doors_per_room:
			x.place_element(door.instantiate())
	)
	rooms.map(func(x): x.generate_items())
