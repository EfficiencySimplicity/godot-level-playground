extends Node2D

@onready var po = $PortalOrigin
@onready var sprite = $Sprite2D

@export var speed: float

func point_is_ok(pos: Vector2):
	var pqparams = PhysicsPointQueryParameters2D.new()
	pqparams.collision_mask = 0b00000000_00000000_00000000_00000001
	pqparams.position = pos + Vector2.from_angle(sprite.global_rotation) * sprite.global_scale.x * 64
	
	return get_viewport().get_world_2d().get_direct_space_state().intersect_point(pqparams).size() == 0
	
		
func _process(delta):
	
	if !Input.is_action_pressed("Movement"):
		return
	
	if Input.is_action_pressed("Left"):
		sprite.rotation_degrees = 180
	elif Input.is_action_pressed("Right"):
		sprite.rotation_degrees = 0
	elif Input.is_action_pressed("Up"):
		sprite.rotation_degrees = -90
	elif Input.is_action_pressed("Down"):
		sprite.rotation_degrees = 90
		
	var move = po.get_move(Vector2.from_angle(sprite.global_rotation) * speed * delta)
	
	if !point_is_ok(move.ort.pos): return
	
	global_position = move.ort.pos
	global_rotation_degrees += move.ort.rot
	po.global_rotation_degrees = 0
	po.current_room = move.room
	po.gen_portals()
