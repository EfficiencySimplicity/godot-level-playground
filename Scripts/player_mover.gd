extends Node2D

@onready var raycast = $RayCast2D
@export var cell_size: int = 64
@onready var half_cell = Vector2(.5, .5) * cell_size

func _input(event):
	if !Input.is_action_pressed("Movement"):
		return
		
	print("Movement is requested!")
	
	if Input.is_action_pressed("Left"):
		rotation_degrees = 180
	elif Input.is_action_pressed("Right"):
		rotation_degrees = 0
	elif Input.is_action_pressed("Up"):
		rotation_degrees = -90
	elif Input.is_action_pressed("Down"):
		rotation_degrees = 90
		
	raycast.force_raycast_update()
		
	if raycast.is_colliding():
		return
		
	print("position was ", position)
	position += Vector2.from_angle(rotation) * cell_size
	print("position wants to be ", position)
	position = ((position-half_cell) / cell_size).round() * cell_size + half_cell
	print("position is ", position)
	
