extends Node2D

@onready var room_generator = preload("res://Scenes/room_generator.tscn")
@export var num_rooms: int
@export var room_gap: int

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
		
	rooms.map(func(x): x.generate())
