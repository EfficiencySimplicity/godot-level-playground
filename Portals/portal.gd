@tool
class_name Portal extends Node2D

@export var room: PortalRoom
@export var other: Portal

@export var width: float:
	set(v):
		width = v
		queue_redraw()

@export var debug: bool:
	set(v):
		debug = v
		queue_redraw()

func connect_portal(_other: Portal):
	other = _other
	other.other = self

# https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html
func _draw():
	if !debug: return
	
	if other:
		draw_line(to_local(global_position), to_local(other.global_position), Color.CRIMSON, 2.0)
		draw_circle(to_local(global_position), 5, Color.GREEN_YELLOW)
	
	draw_circle(to_local(get_start()), 5, Color.RED)
	draw_circle(to_local(get_end()), 5, Color.RED)

func port(orientation: Orientation) -> Orientation:
	var relative_pos = orientation.pos - global_position
	# https://github.com/godotengine/godot-proposals/discussions/9996
	var rot_difference = rotation_change_through()
	var new = Orientation.new(other.global_position, rot_difference).map_vector2(relative_pos)
	return Orientation.new(new, orientation.rot + rot_difference)
	
func port_pos(pos: Vector2) -> Vector2:
	return Orientation.new(other.global_position, rotation_change_through()).map_vector2(pos - self.global_position)


func is_in_front(pos: Vector2):
	return Vector2.from_angle(global_rotation + deg_to_rad(90)).dot(pos - global_position) > 0

func get_normal():
	return Vector2.from_angle(deg_to_rad(global_rotation_degrees + 90))
	
func get_out_normal():
	return get_normal() * -1
	
func distance_to(point: Vector2) -> float:
	return (get_start() - point).dot(get_out_normal())
	
func cast_on(point: Vector2, dir: Vector2, distance = null, distance_along_self = null) -> Vector2:
	if !distance: distance = distance_to(point)
	if !distance_along_self: distance_along_self = dir.dot(get_out_normal())
	return point + dir * (distance / distance_along_self)
	
func get_vec_along():
	return (get_end() - get_start()).normalized()
	
func get_start():
	return global_position - (Vector2.from_angle(global_rotation) * (width / 2) * .99)

func get_end():
	return global_position + (Vector2.from_angle(global_rotation) * (width / 2) * .99)
	
func rotation_change_through():
	return fmod((other.global_rotation_degrees + 180) - global_rotation_degrees, 360)
