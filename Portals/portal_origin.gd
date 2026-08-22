@tool
class_name PortalOrigin extends Portable

@export var angle_step: int = 5

var all_meshes: Array[ViewMesh]

@export var debug: bool:
	set(v):
		debug = v
		queue_redraw()
		
@export var show_external_bounds: bool:
	set(v):
		show_external_bounds = v
		queue_redraw()
	
func gen_portals():
	if !current_room: return
		
	all_meshes = get_meshes(current_room, global_position)
	all_meshes.sort_custom(func(a, b): return b.y > a.y)
	queue_redraw()
	return

	
## Given a room and position within that room, get all the meshes you can from lookin' thru that
## room's portals; optionally looking through a portal *into* that room, in which case limits are given.
func get_meshes(room: PortalRoom, pos: Vector2, iter = 0, cast_from = null, min_limit = null, max_limit = null) -> Array[ViewMesh]:
	var meshes: Array[ViewMesh] = []

	for portal in room.portals:
		if portal == cast_from: continue
		
		var vis_range = get_visible_portal_range(portal, pos, cast_from, min_limit, max_limit)
		
		if vis_range.is_empty():
			if is_drawing: draw_line(to_local(pos), to_local(portal.global_position), Color.BLACK)
			continue
			
		#if is_drawing:
			#draw_line(to_local(pos), to_local(vis_range[0]), Color.BLUE)
			#draw_line(to_local(pos), to_local(vis_range[1]), Color.BLUE)
		
		# ask the room to give us a mesh
		var mesh = portal.other.room.get_extended_mesh_from_portal(
			portal.other,
			portal.port_pos(pos), 
			[portal.port_pos(vis_range[0]), portal.port_pos(vis_range[1])]
		)

		meshes.append(mesh)
		
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
		
		
func angle_range(min_angle, max_angle, step):
	var r = []
	var s = min_angle
	while s < max_angle:
		r.append(s)
		s += step
	r.append(max_angle)
	return r
	
## The PortalOrigin needs to imagine itself in a virtual place inside another room sometimes,
## so we can pass in test_pos as the position to test from.
## along with a portal we're looking thru to cast from,
## along with the angle range we have to look thru this door.
func get_visible_portal_range(portal: Portal, pos = null, cast_from = null, min_limit = null, max_limit = null) -> Array[Vector2]:
	pos = pos if pos else global_position
	var pos_on_plane = cast_from.cast_on(pos, cast_from.get_normal()) if cast_from else pos
	
	if !portal.is_in_front(pos_on_plane):
		return []
			
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
	
	if end_angle < start_angle:
		end_angle += 360
		
	# not enough to know about the portal, we must also know where on the portal we can see...
	# if we have the portal, we'll have the limits too!
	# this block tests if the portal (inside the room we're looking into) 
	# is visible from the part of the portal we can see through
	if cast_from:
		var min_angle = rad_to_deg(pos.angle_to_point(min_limit))
		var max_angle = rad_to_deg(pos.angle_to_point(max_limit))
		
		if max_angle < min_angle:
			max_angle += 360
			
		if is_drawing:
			draw_circle(to_local(max_limit), 2, Color.RED)
			draw_circle(to_local(min_limit), 2, Color.RED)
			draw_line(to_local(pos), to_local(pos + Vector2.from_angle(deg_to_rad(min_angle)) * 30), Color.RED, 5)
			draw_line(to_local(pos), to_local(pos + Vector2.from_angle(deg_to_rad(max_angle)) * 30), Color.RED, 5)
			
		if Utils.compare_angles(max_angle, start_angle):
			return []
			
		if Utils.compare_angles(end_angle, min_angle):
			return []
			
		if Utils.compare_angles(start_angle, min_angle):
			start_angle = min_angle
			
		if Utils.compare_angles(max_angle, end_angle):
			end_angle = max_angle
			
	if is_drawing:
		draw_line(to_local(pos), to_local(pos + Vector2.from_angle(deg_to_rad(start_angle)) * 20), Color.ORANGE, 2)
		draw_line(to_local(pos), to_local(pos + Vector2.from_angle(deg_to_rad(end_angle)) * 20), Color.ORANGE, 2)
		
	var min_ok_point = Vector2.ZERO
	var max_ok_point = Vector2.ZERO
	
	var has_hit_at_all = false

	# start and end angle are both positive (end may be > 360),
	# and end is clockwise from start
	var scaled_angle_step = float(end_angle - start_angle) / ceil((end_angle - start_angle) / angle_step)

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
			0b00000000_00000000_00000000_00000010
		)
		
		if is_drawing:
			draw_line(to_local(start_pos), to_local(hit_point), Color.GREEN)
		
		var hit = get_viewport() \
		.get_world_2d() \
		.get_direct_space_state() \
		.intersect_ray(rcparams) \
		.size() != 0
		
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
@export_tool_button("Redraw line") var redraw = queue_redraw
func _draw():
	is_drawing = true
	
	if !(current_room): is_drawing = false; return
	
	if !Engine.is_editor_hint():
		all_meshes.map(
			func(x):
				draw_mesh(x.get_mesh(), x.room.texture, Transform2D(0, to_local(Vector2.ZERO)))
				var color = Color.from_rgba8(x.y * 64, x.y * 64, x.y * 64)
				Array(x.vertices).map(func(v): draw_circle(to_local(v), 10 - x.y * 3, color))
		)
		
		get_meshes(current_room, global_position)
				
	
	if (!Engine.is_editor_hint() or !debug): is_drawing = false; return
	
	for portal in current_room.portals:
		var vis_range = get_visible_portal_range(portal)
		
		if vis_range.is_empty():
			draw_line(to_local(global_position), to_local(portal.global_position), Color.BLACK)
			continue
		
		draw_line(to_local(global_position), to_local(vis_range[0]), Color.BLUE)
		draw_line(to_local(global_position), to_local(vis_range[1]), Color.BLUE)
		
		# get all the meshes in the room and transform 'em back and draw the verts
		var mesh = portal.other.room.get_extended_mesh_from_portal(
			portal.other,
			portal.port_pos(global_position), 
			[portal.port_pos(vis_range[0]), portal.port_pos(vis_range[1])]
		)
		
		draw_polyline(mesh.vertices.map(func(x): return to_local(x)), Color.AQUA)
		mesh.vertices.map(func(x): draw_circle(to_local(x), 5, Color.AQUA))
		
		if show_external_bounds:
			var bounds_color = Color.HOT_PINK
			bounds_color.a = .25
			
			var bounds = portal.other.room.bounds
			var pos = portal.other.port_pos(bounds.position)
			var size = portal.other.port_pos(bounds.position + bounds.size) - pos
			
			draw_rect(
				Rect2(
					to_local(pos.min(pos + size)),
					pos.max(pos + size) - pos.min(pos + size)
				),
				bounds_color
			)
			
	is_drawing = false;
