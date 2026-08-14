class_name Door extends Node2D

@export var room: RoomGenerator;
@export var other: Door = self
@export var debug: bool

func connect_door(_other: Door):
	other = _other
	other.other = self

# https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html
func _draw():
	if !debug: return
	draw_line(to_local(global_position), to_local(other.global_position), Color.CRIMSON, 2.0)
	draw_circle(to_local(Orientation.from_object(self).to_placement().cell_center()), 15, Color.BLUE)
	# draw_texture.call_deferred(room.viewport.get_texture(), Vector2(0, 0))
	
func door_transform(orientation: Orientation) -> Orientation:
	var relative_pos = orientation.pos - Orientation.from_object(self).pos
	var rot_difference = int((other.global_rotation_degrees + 180) - global_rotation_degrees) % 360
	var new = Orientation.new(other.global_position, rot_difference).map_vector2(relative_pos)
	return Orientation.new(new, orientation.rot + rot_difference)

func is_in_front(pos: Vector2):
	return Vector2.from_angle(rotation).dot(pos - global_position) > 0
