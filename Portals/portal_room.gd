@tool
class_name PortalRoom extends Node2D

@export var portals: Array[Portal]
@onready var viewport: SubViewport = $SubViewport
@onready var render_mesh: MeshInstance2D = $RenderMesh

func _ready():
	viewport.world_2d = get_world_2d()
	render_mesh.global_position = Vector2.ZERO
	update_viewport()
	
# https://shaggydev.com/2022/09/27/godot-4-setter-getter/
@export var bounds: Rect2:
	set(v):
		bounds = v
		queue_redraw()
		if !viewport: return
		update_viewport()

func update_viewport():
	viewport.size = bounds.size
	viewport.get_child(0).global_position = bounds.position + (bounds.size / 2)

@export var debug: bool:
	set(v):
		debug = v
		queue_redraw()

func _draw():
	if !debug: return
	draw_rect(Rect2(to_local(bounds.position), bounds.size), Color.from_rgba8(255, 255, 0, 128))
	
## The portal should be one *in this room*, with the point and vis range
## being transformed to be looking *into* this room *from* outside.
## It transforms the coordinates back into the other room's space at the end
func get_extended_mesh_from_portal(portal: Portal, view_point: Vector2, vis_range: Array[Vector2]) -> MeshPool:
	var min_angle = rad_to_deg(view_point.angle_to_point(vis_range[0]))
	var max_angle = rad_to_deg(view_point.angle_to_point(vis_range[1]))
	
	var min_dir = (vis_range[0] - view_point).normalized()
	var max_dir = (vis_range[1] - view_point).normalized()
	
	# we get what corners of the room are within the angle range
	var ok_corners = Utils.get_corners(bounds).filter(
		func(corner): 
			var angle_to = rad_to_deg(view_point.angle_to_point(corner))
			return Utils.compare_angles(min_angle, angle_to) and Utils.compare_angles(angle_to, max_angle)
	)
	
	ok_corners.sort_custom(
		func(corner_a, corner_b):
			return Utils.compare_angles(
				rad_to_deg(view_point.angle_to_point(corner_a)),
				rad_to_deg(view_point.angle_to_point(corner_b))
			)
	)
	
	# extend the min and max of the view range until they hit the walls
	var min_extended = Utils.extend_to_rect_edge(bounds, vis_range[0], min_dir)
	var max_extended = Utils.extend_to_rect_edge(bounds, vis_range[1], max_dir)

	# create the array of points; going clockwise:
	# - the first point on the door that's visible - that point extended 'til it hits the room edge
	var pts = [vis_range[0], min_extended]
	# - all the corners between that point and...
	pts.append_array(ok_corners)
	# - the last point on the door that's visible, extended, and then - not extended
	pts.append_array([max_extended, vis_range[1]])

	var triangles: PackedInt32Array = []
	# basic fan method
	for i in range(pts.size() - 1):
		triangles.append(0)
		triangles.append(i)
		triangles.append(i + 1)
		
	var uvs: PackedVector2Array = PackedVector2Array(pts.map(func(x): return to_uv(x)))
		
	return MeshPool.new(
		PackedVector2Array(pts.map(func(x): return portal.port_pos(x))),
		triangles,
		uvs
	)

func to_uv(pos: Vector2) -> Vector2:
	return ((pos - bounds.position) / bounds.size).clamp(Vector2.ZERO, Vector2.ONE)

func fromto(from: Orientation, to: Orientation):
	pass
