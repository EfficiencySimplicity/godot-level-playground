extends Node2D

@export var debug: bool

@onready var raycast = $RayCast2D
@onready var sprite = $Sprite2D

@export var cell_size: int = 64
@onready var half_cell = Vector2(.5, .5) * cell_size

func _input(_event):
	if !Input.is_action_pressed("Movement"):
		return
		
	print("Movement is requested!")
	
	if Input.is_action_pressed("Left"):
		sprite.rotation_degrees = 180
	elif Input.is_action_pressed("Right"):
		sprite.rotation_degrees = 0
	elif Input.is_action_pressed("Up"):
		sprite.rotation_degrees = -90
	elif Input.is_action_pressed("Down"):
		sprite.rotation_degrees = + 90
		
	var new_placement = get_tree().current_scene.get_next_move_orientation(sprite)
	
	var pqparams = PhysicsPointQueryParameters2D.new()
	pqparams.collision_mask = 0b00000000_00000000_00000000_00000001
	pqparams.position = new_placement.pos
	
	print(get_viewport().get_world_2d().get_direct_space_state().intersect_point(pqparams).size())
	if get_viewport().get_world_2d().get_direct_space_state().intersect_point(pqparams).size() != 0:
		return
	
	global_position = new_placement.pos
	var rot_offset = new_placement.rot - sprite.global_rotation_degrees
	global_rotation_degrees += rot_offset
	sprite.rotation_degrees -= rot_offset	
	
	global_rotation_degrees = round(global_rotation_degrees / 90) * 90
	sprite.global_rotation_degrees = round(sprite.global_rotation_degrees / 90) * 90
	
	global_position = Orientation.from_object(self).to_placement().to_orientation().translate(half_cell).pos
	
func _draw():
	if !debug: return
	draw_circle(to_local(Orientation.from_object(self).to_placement().cell_center()), 150, Color.GREEN)
