@tool
class_name PortalOrigin extends Portable

## A Portable that renders meshes of what it can see through all the portals in its room

## The angle step when raycasting to see what is visible
@export var angle_step: int = 5
## How many rooms to render through; 
## portals in the room you're looking into will also have ViewMeshes rendered for 'em.
## A value of 0 only renders one iteration deep
@export var iterations: int = 0
## The raycast mask; set this to be blocked by walls or whatever.
@export_flags_2d_physics var raycast_mask: int

@onready var space_state : PhysicsDirectSpaceState2D:
	get():
		if !space_state:
			space_state = get_viewport().get_world_2d().get_direct_space_state()
			
		return space_state
## If this is set to true, the ViewMeshes will be recalculated each frame.
## It's better to manually call gen_meshes() in code only when ya need it though;
## although Godot seems to handle this pretty well.
@export var gen_each_frame: bool

var all_meshes: Array[ViewMesh]
		
## Show the bounds of all rooms one room away from the current one
@export var show_external_bounds: bool:
	set(v):
		show_external_bounds = v
		queue_redraw()
## Show the raycast test angles to each portal in the current room
@export var show_test_angles: bool:
	set(v):
		show_test_angles = v
		queue_redraw()
## Show the min and max points visible on each portal in the current room
@export var show_portal_visibility_ranges: bool:
	set(v):
		show_portal_visibility_ranges = v
		queue_redraw()
## Show the bounds of the meshes visible from the portals in the current room
@export var show_mesh_bounds: bool:
	set(v):
		show_mesh_bounds = v
		queue_redraw()
	
func _process(_delta):
	if Engine.is_editor_hint(): return
	if gen_each_frame: gen_portals()
	
## Generates and stores all the ViewMeshes from the current position
func gen_portals():
	if !current_room: return
		
	all_meshes = get_meshes(current_room, global_position, iterations)
	all_meshes.sort_custom(func(a, b): return b.y > a.y)
	
	queue_redraw()

	
## Given a room and position within that room, get all the meshes you can from lookin' thru that
## room's portals; and the iter parameter is for recursion;
## you might choose to render meshes inside the rooms you can see into;
## in which case you transform your position to be outside that room looking in,
## set cast_from to be the portal you're looking inTO, and set the limits to 
## the min and max points of the portal you could see.
## I can't explain all this with ASCII art, just trust me. 
func get_meshes(room: PortalRoom, pos: Vector2, iter = 0, cast_from = null, min_limit = null, max_limit = null) -> Array[ViewMesh]:
	var meshes: Array[ViewMesh] = []

	for portal in room.portals:
		# heh, no, this is the portal we're looking in FROM, no use considering it.
		if portal == cast_from: continue
		
		var vis_range = get_visible_portal_range(portal, pos, cast_from, min_limit, max_limit)
		
		if vis_range.is_empty():
			# we cannot see any of this portal
			if is_drawing: draw_line(pos, portal.global_position, Color.BLACK)
			continue
		elif is_drawing and show_portal_visibility_ranges:
			draw_line(global_position, vis_range[0], Color.BLUE)
			draw_line(global_position, vis_range[1], Color.BLUE)
		
		# ask the room to give us a ViewMesh of what we can see thru that portal
		var mesh = portal.other.room.get_extended_mesh_from_portal(
			portal.other,
			portal.port_pos(pos), 
			[portal.port_pos(vis_range[0]), portal.port_pos(vis_range[1])]
		)

		meshes.append(mesh)
		
		# look thru the portal and get the meshes IT can see
		if iter > 0:
			meshes.append_array(
				get_meshes(
					portal.other.room,
					portal.port_pos(pos),
					iter-1,
					portal.other,
					portal.port_pos(vis_range[0]),
					portal.port_pos(vis_range[1]))
				.map(func(x): 
						# transform the vertices back thru the portal
						return ViewMesh.new(
							x.vertices.map(func(v): return portal.other.port_pos(v)),
							x.triangles,
							x.uvs,
							x.room,
							x.y + 1
						)
						)
				)

	return meshes
		
## this is like range(), but floats are OK, plus 
## it takes the fact that rotation loops back around into account;
## 359 degrees is only a little bit away from 2 degrees
func angle_range(min_angle, max_angle, step):
	if max_angle < min_angle: max_angle += 360
	if abs(max_angle - min_angle) > 180: min_angle += 360
	var r = []
	var s = min_angle
	while s < max_angle:
		r.append(s)
		s += step
	r.append(max_angle)
	return r
	
## Basically, given a portal, this shoots out raycasts and tells you the
## first and last visible points on the portals surface (going clockwise). [br]
## [br]
## The PortalOrigin needs to imagine itself in a virtual place inside another room sometimes,
## so we can pass in test_pos as the position to test from.
## along with a portal we're looking thru to cast from,
## along with the angle range we have to look thru this portal.
func get_visible_portal_range(portal: Portal, pos, cast_from = null, min_limit = null, max_limit = null) -> Array[Vector2]:
	var pos_on_plane = cast_from.cast_on(pos, cast_from.get_normal()) if cast_from else pos
	
	if !portal.is_in_front(pos_on_plane): return []
	if cast_from and !cast_from.is_in_front(portal.get_start()) and !cast_from.is_in_front(portal.get_end()): return []

	var start = portal.get_start()
	var end   = portal.get_end()
	var out_normal = portal.get_out_normal()
		
	# from you to the door-line
	var distance = portal.distance_to(pos)
	
	if distance < 1:
		pos -= out_normal * (1 - distance)
		distance = 1
		
	var start_angle = rad_to_deg(pos.angle_to_point(start))
	var end_angle = rad_to_deg(pos.angle_to_point(end))
	
	# not enough to know about the portal, we must also know where on the portal we can see...
	# if we have the portal, we'll have the limits too!
	# this block tests if the portal (inside the room we're looking into) 
	# is visible from the part of the portal we can see through
	if cast_from:
		var min_angle = rad_to_deg(pos.angle_to_point(min_limit))
		var max_angle = rad_to_deg(pos.angle_to_point(max_limit))
		# the portal ends before our view range even starts
		if Utils.compare_angles(max_angle, start_angle): return []
		# the portal starts after our view range ends
		if Utils.compare_angles(end_angle, min_angle): return []
		# the portal starts before our view range starts; edit the angle
		if Utils.compare_angles(start_angle, min_angle): start_angle = min_angle
		# the portal ends after our view range ends; edit the angle
		if Utils.compare_angles(max_angle, end_angle): end_angle = max_angle

	var min_ok_point = Vector2.ZERO
	var max_ok_point = Vector2.ZERO
	
	var has_hit_at_all = false

	# start and end angle are both positive (end may be > 360),
	# and end is clockwise from start

	for current_angle in angle_range(start_angle, end_angle, angle_step):
		
		# https://forum.godotengine.org/t/how-to-get-a-portion-of-a-vector-that-is-aligned-with-another-vector/40426/4
		var direction = Vector2.from_angle(deg_to_rad(current_angle))
		# where on the door-line we test
		var hit_point = portal.cast_on(pos, direction, distance)
		
		# TODO: distance to the casting plane!!!
		var start_pos = pos if !cast_from else cast_from.cast_on(pos, direction)
		
		var rcparams = PhysicsRayQueryParameters2D.create(
			start_pos,
			hit_point,
			raycast_mask
		)
		
		if is_drawing and show_test_angles:
			draw_line(start_pos, hit_point, Color.GREEN)
		
		# TODO: naming if hit an has_hit_at_all have different meanings...
		var hit = space_state.intersect_ray(rcparams).size() != 0

		if hit:
			if has_hit_at_all:
				break
		else:
			if !has_hit_at_all:
				has_hit_at_all = true
				min_ok_point = hit_point

			max_ok_point = hit_point
			
	if !has_hit_at_all:
		return []
	
	return [min_ok_point, max_ok_point]
	
var is_drawing = false;

# https://www.reddit.com/r/godot/comments/17fed5p/is_there_a_way_to_put_a_button_on_the_inspector/
@export_tool_button("Redraw debug lines") var redraw = queue_redraw
func _draw():
	is_drawing = true
	
	if !(current_room): is_drawing = false; return
	
	draw_set_transform_matrix(global_transform.affine_inverse())
	
	if !Engine.is_editor_hint():
		for x in all_meshes:
			draw_mesh(x.get_mesh(), x.room.texture, Transform2D(0, Vector2.ZERO))
		# sometimes the draw system needs an extra slap in the face to remember to draw the meshes above
		# this non-circle does the job somehow
		draw_circle(Vector2.ZERO, 0, Color.RED)
	
	if (show_test_angles or show_portal_visibility_ranges or show_mesh_bounds):
		# we get the meshes with an iter of zero, and since we're drawing, the debug data gets shown!
		var meshes = get_meshes(current_room, global_position)
		
		if show_mesh_bounds:
			meshes.map(
				func(mesh): 
					draw_polyline(mesh.vertices, Color.AQUA)
					mesh.vertices.map(func(v): draw_circle(v, 5, Color.AQUA))
			)
		
	if show_external_bounds:
		var bounds_color = Color.HOT_PINK
		bounds_color.a = .25
		
		for portal in current_room.portals:
		
			var bounds = portal.other.room.bounds
			var pos = portal.other.port_pos(bounds.position)
			var size = portal.other.port_pos(bounds.position + bounds.size) - pos
			
			draw_rect(
				Rect2(
					pos.min(pos + size),
					pos.max(pos + size) - pos.min(pos + size)
				),
				bounds_color
			)
			
	is_drawing = false;
