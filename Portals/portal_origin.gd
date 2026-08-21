@tool
class_name PortalOrigin extends Portable

@export var angle_increase: int = 5
var meshes: Array[PortalVisionArea]

class PortalVisionArea:
	var mesh: ArrayMesh
	var room: PortalRoom
	var y: int
	
	func _init(_mesh: ArrayMesh, _room: PortalRoom, _y: int):
		mesh = _mesh
		room = _room
		y = _y

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
		
	meshes = []
	
	for portal in current_room.portals:
		
		var vis_range = get_visible_portal_range(portal)
		
		if vis_range.is_empty():
			continue
		
		# get all the meshes in the room and transform 'em back and draw the verts
		var mesh_pool = portal.other.room.get_extended_mesh_from_portal(
			portal.other,
			portal.port_pos(global_position), 
			[portal.port_pos(vis_range[0]), portal.port_pos(vis_range[1])]
		)

		meshes.append(
			PortalVisionArea.new(mesh_pool.to_mesh(), portal.other.room, 1)
		)

	meshes.sort_custom(func(a, b): return b.y > a.y)
	queue_redraw()
		
## The PortalOrigin needs to imagine itself in a virtual place inside another room sometimes,
## so we can pass in test_pos as the position to test from.
## along with a portal we're looking thru to cast from,
## along with the angle range we have to look thru this door.
func get_visible_portal_range(portal: Portal, test_pos = null, cast_from = null, min_angle = null, max_angle = null) -> Array[Vector2]:
	if !portal.is_in_front(global_position):
		return []
			
	var start = portal.get_start()
	var end   = portal.get_end()
	var out_normal = portal.get_out_normal()
		
	# from you to the door-line
	var distance = portal.distance_to(global_position)
	
	if !test_pos: test_pos = global_position
	
	if distance < 1:
		test_pos -= out_normal * (1 - distance)
		distance = 1
		
	var start_angle = rad_to_deg(global_position.angle_to_point(start))
	var end_angle = rad_to_deg(global_position.angle_to_point(end))
	
	if end_angle < start_angle:
		end_angle += 360

	var min_ok_point = Vector2.ZERO
	var max_ok_point = Vector2.ZERO
	
	var has_hit_at_all = false
	
	# make a range explicitly to include the end angle, which may not be hit otherwise
	var angle_range = range(start_angle, end_angle, angle_increase)
	angle_range.append(end_angle)
	
	for current_angle in angle_range:
		
		# https://forum.godotengine.org/t/how-to-get-a-portion-of-a-vector-that-is-aligned-with-another-vector/40426/4
		var direction = Vector2.from_angle(deg_to_rad(current_angle))
		# where on the door-line we test
		var hit_point = portal.cast_on(test_pos, direction, distance)
		
		var rcparams = PhysicsRayQueryParameters2D.create(
			test_pos,
			hit_point,
			0b00000000_00000000_00000000_00000010
		)
		
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
	
# https://www.reddit.com/r/godot/comments/17fed5p/is_there_a_way_to_put_a_button_on_the_inspector/
@export_tool_button("Redraw line") var redraw = queue_redraw
func _draw():
	if !(current_room): return
	
	if !Engine.is_editor_hint():
		meshes.map(func(x): draw_mesh(x.mesh, x.room.texture, Transform2D(0, to_local(Vector2.ZERO))))
	
	if (Engine.is_editor_hint() and !debug): return
	
	for portal in current_room.portals:
		var vis_range = get_visible_portal_range(portal)
		
		if vis_range.is_empty():
			draw_line(to_local(global_position), to_local(portal.global_position), Color.BLACK)
			return
		
		draw_line(to_local(global_position), to_local(vis_range[0]), Color.BLUE)
		draw_line(to_local(global_position), to_local(vis_range[1]), Color.BLUE)
		
		# get all the meshes in the room and transform 'em back and draw the verts
		var mesh = portal.other.room.get_extended_mesh_from_portal(
			portal.other,
			portal.port_pos(global_position), 
			[portal.port_pos(vis_range[0]), portal.port_pos(vis_range[1])]
		)
		
		draw_polyline(Array(mesh.vertices).map(func(x): return to_local(x)), Color.AQUA)
		Array(mesh.vertices).map(func(x): draw_circle(to_local(x), 5, Color.AQUA))
		
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
	
		#
#func _process(delta):
	#queue_redraw()
