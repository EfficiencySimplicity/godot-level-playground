class_name PortalRoom extends Node2D

@export var portals: Array[Portal]
@onready var viewport: SubViewport = $SubViewport
@onready var render_mesh: MeshInstance2D = $RenderMesh

func _ready():
	viewport.world_2d = get_world_2d()
	render_mesh.global_position = Vector2.ZERO
	
# https://shaggydev.com/2022/09/27/godot-4-setter-getter/
@export var bounds: Rect2:
	set(v):
		viewport.size = bounds.size
		viewport.get_child(0).global_position = bounds.position + (bounds.size / 2)


@export var debug: bool

func _draw():
	if !debug: return
	draw_rect(bounds, Color.from_rgba8(255, 255, 0, 128))
	
func fromto(from: Orientation, to: Orientation):
	
