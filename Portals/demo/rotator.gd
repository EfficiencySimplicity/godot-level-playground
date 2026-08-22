extends Area2D

@export var speed: int
@onready var rotating_body = $AnimatableBody2D

var do_rotate = true

func _on_area_entered(body: Node2D) -> void:
	if body.name == "Player":
		do_rotate = false

func _on_area_exited(body: Node2D) -> void:
	if body.name == "Player":
		do_rotate = true
	
func _physics_process(delta):
	if !do_rotate: return
	
	rotating_body.rotate(speed * delta)
