class_name DebugDot extends Node2D

@export var color: Color
@export var radius: float = 20

func _draw():
	draw_circle(to_local(global_position), radius, color)
