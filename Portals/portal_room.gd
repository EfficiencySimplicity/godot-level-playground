@tool
class_name PortalRoom extends Node2D
## A PortalRoom holds references to a number of Portals and handles rendering. [br]
## It manages a SubViewport and ViewportTexture, so all the portals inside it can
## use its texture, instead of a camera / viewport / texture for each Portal.

## All the portals this room owns (not necessarily children of it)
@export var portals: Array[Portal]:
	set(v):
		if v == portals: return
		
		var added   =       v.filter(func(x): return !portals.has(x))
		var deleted = portals.filter(func(x): return !v.has(x))
		
		added.map(func(x): if x.room != self: x.room = self)
		deleted.map(func(x): if x.room == self: x.room = null)
		
		if debug: queue_redraw()
		
## The SubViewport used for rendering all views into this Room
@onready var viewport: SubViewport = $SubViewport
## The ViewportTexture this room renders to
@export var texture: ViewportTexture

# https://shaggydev.com/2022/09/27/godot-4-setter-getter/
## The room bounds. This should contain everything that should be visible when looking into the room.
## It should also encompass all Portals within the room, with a little bit of extra margin.
var bounds: Rect2:
	get():
		return Rect2(global_position, size)

@export var size: Vector2 = Vector2.ONE * 64:
	set(v):
		size = v
		queue_redraw()
		if viewport: update_viewport()
		
@export var debug: bool:
	set(v):
		debug = v
		queue_redraw()
		
@export_tool_button("Collect all Portals within bounds") var cpwb = collect_portals_within_bounds
func collect_portals_within_bounds():
	var scene
	if Engine.is_editor_hint():
		scene = get_tree().edited_scene_root
	else:
		scene = get_tree().current_scene
		
	if !scene:
		push_error("Could not get current scene")
		
	var portals_within_bounds = scene.find_children("*", "Portal", true, false).filter(
		func(portal):
			return bounds.has_point(portal.global_position)
	)
	
	var typed_portal_array: Array[Portal]
	typed_portal_array.assign(portals_within_bounds)

	portals = typed_portal_array
		

func _ready():
	# by default, viewports only render their little worlds inside. We don't want that.
	viewport.world_2d = get_world_2d()
	update_viewport()

## Makes the room's viewport encompass its bounds, for obvious reasons
func update_viewport():
	viewport.size = bounds.size
	viewport.get_child(0).global_position = bounds.position + (bounds.size / 2)

func _draw():
	if !debug: return
	draw_set_transform_matrix(global_transform.affine_inverse())
	
	draw_rect(bounds, Color.from_rgba8(255, 255, 0, 128))
	
	for portal in portals:
		var c = Color.RED
		for i in 5:
			draw_circle(portal.global_position, i * 10, c)
			c.a -= .8 / 5
			
## Say an origin in another room is looking into this room; we need to give that origin
## the shape of the mesh it can see. We take: [br]
##
## - The portal (in this room) that's being looked through, [br]
## - The origin position (transformed to be behind the portal in this room), [br]
## - The min and max points (transformed to be on the portal in this room) that the origin can see [br]
##[br]
## And we return a ViewMesh, which we transform back through the portal in this room, so the mesh
## is positioned out behind the portal in the other room, for its convenience
func get_extended_mesh_from_portal(portal: Portal, view_point: Vector2, vis_range: Array[Vector2]) -> ViewMesh:
	
	# we have the min and max *points* the origin can see, we need the *angles*
	var min_angle = rad_to_deg(view_point.angle_to_point(vis_range[0]))
	var max_angle = rad_to_deg(view_point.angle_to_point(vis_range[1]))
	
	# the directions from the origin to each of the points, for extending as an edge
	var min_dir = (vis_range[0] - view_point).normalized()
	var max_dir = (vis_range[1] - view_point).normalized()
	
	# we get what corners of the room are within the angle range
	var ok_corners = Utils.get_corners(bounds).filter(
		func(corner): 
			var angle_to = rad_to_deg(view_point.angle_to_point(corner))
			return Utils.compare_angles(min_angle, angle_to) and Utils.compare_angles(angle_to, max_angle)
	)
	
	# sort 'em in clockwise order
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
	# - the first point on the portal that's visible - that point extended 'til it hits the room edge
	var pts = [vis_range[0], min_extended]
	# - all the corners between that point and...
	pts.append_array(ok_corners)
	# - the last point on the portal that's visible, extended, and then - not extended
	pts.append_array([max_extended, vis_range[1]])
	
	# Here is an ASCII representation of what all that means
	
	# 2--------3
	# |        |
	# |1      4|  <- order and position of the points we use to make the ViewMesm
	# | \    / |
	# |  \  /  |
	# ---0__5---
	#
	#      . <- origin (transformed, it's in another room really)
	
	# Now we make the ViewMesh

	var triangles = []
	# basic fan method
	for i in range(pts.size() - 1):
		triangles.append(0)
		triangles.append(i)
		triangles.append(i + 1)
		
	return ViewMesh.new(
		pts.map(func(x): return portal.port_pos(x)), # transform back into the other room
		triangles,
		pts.map(func(x): return to_uv(x)),
		self,
		1
	)

## Given a point in world space, tells you the UV of that point in the room's ViewportTexture.
## Naturally, the point should be within the room bounds
func to_uv(pos: Vector2) -> Vector2:
	return ((pos - bounds.position) / bounds.size).clamp(Vector2.ZERO, Vector2.ONE)
