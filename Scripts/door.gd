class_name Door extends Node2D

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

func teleport(orientation: Orientation) -> Orientation:
	var rot_difference = int((other.global_rotation_degrees + 180) - global_rotation_degrees) % 360
	return Orientation.new(other.global_position, orientation.rot + rot_difference)
