class_name Portal extends Node2D

@export var room: PortalRoom;
@export var other: Portal = self

@export var debug: bool

func connect_portal(_other: Portal):
	other = _other
	other.other = self

# https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html
func _draw():
	if !debug: return
	draw_line(to_local(global_position), to_local(other.global_position), Color.CRIMSON, 2.0)
	draw_circle(to_local(Orientation.from_object(self).to_placement().cell_center()), 15, Color.BLUE)
	
	draw_circle(to_local(get_start()), 5, Color.RED)
	draw_circle(to_local(get_end()), 5, Color.RED)

func port(orientation: Orientation) -> Orientation:
	var relative_pos = orientation.pos - Orientation.from_object(self).pos
	var rot_difference = int((other.global_rotation_degrees + 180) - global_rotation_degrees) % 360
	var new = Orientation.new(other.global_position, rot_difference).map_vector2(relative_pos)
	return Orientation.new(new, orientation.rot + rot_difference)
	
func port_pos(pos: Vector2) -> Vector2:
	var relative_pos = pos - self.global_position
	var rot_difference = int((other.global_rotation_degrees + 180) - global_rotation_degrees) % 360
	return Orientation.new(other.global_position, rot_difference).map_vector2(relative_pos)


func is_in_front(pos: Vector2):
	return Vector2.from_angle(global_rotation + deg_to_rad(90)).dot(pos - global_position) >= 0

func get_normal():
	return Vector2.from_angle(deg_to_rad(global_rotation_degrees + 90))
	
func get_start():
	return global_position - (Vector2.from_angle(global_rotation) * (global_scale.x / 2) * .99 * 64)

func get_end():
	return global_position + (Vector2.from_angle(global_rotation) * (global_scale.x / 2) * .99 * 64)
