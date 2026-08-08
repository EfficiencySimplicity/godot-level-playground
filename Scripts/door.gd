class_name Door extends Node2D

@export var other: Door = self

func connect_door(_other: Door):
	other = _other
	other.other = self

# https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html
func _draw():
	draw_line(position, to_local(other.global_position), Color.CRIMSON, 2.0)
