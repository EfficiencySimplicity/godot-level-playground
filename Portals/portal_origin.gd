@tool
class_name PortalOrigin extends Node2D

@export var current_room: PortalRoom
@export var angle_increase: int = 5

@export var debug: bool:
	set(v):
		debug = v
		queue_redraw()
	
func gen_portals():
	if current_room == null:
		print("No current room to gen portals from!")
		return
		
	#var mesh_pools: Dictionary[RoomGenerator, MeshPool] = {}
	#for room in get_tree().current_scene.rooms:
		#mesh_pools[room] = MeshPool.new()
		#
	#for door in current_room.doors:
	
	for portal in current_room.portals:
		
		if !portal.is_in_front(global_position):
			continue;
			
		var start = portal.get_start()
		var end   = portal.get_end()
		var out_normal = portal.get_out_normal()
		var dir_to_end = portal.get_vec_along()
		
		# from you to the door-line
		var distance = (start - global_position).dot(out_normal)
		
		var test_pos = global_position
		
		if distance < 1:
			test_pos -= out_normal * (1 - distance)
			distance = 1
			
		var start_angle = rad_to_deg(global_position.angle_to_point(start))
		var end_angle = rad_to_deg(global_position.angle_to_point(end))
		
		if end_angle < start_angle:
			end_angle += 360
			
		var min_ok_angle = -1000000
		var min_ok_point = Vector2.ZERO
		var max_ok_angle = 1000000
		var max_ok_point = Vector2.ZERO
		
		var has_hit_at_all = false
		
		for current_angle in range(start_angle, end_angle, angle_increase):
			
			# https://forum.godotengine.org/t/how-to-get-a-portion-of-a-vector-that-is-aligned-with-another-vector/40426/4
			var direction = Vector2.from_angle(deg_to_rad(current_angle))
			
			var amount_along_normal = direction.dot(out_normal)
			# where on the door-line we test
			var hit_point = test_pos + direction * (distance / amount_along_normal)
			
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
					min_ok_angle = current_angle
					min_ok_point = hit_point
					
				max_ok_angle = current_angle
				max_ok_point = hit_point
				
		if !has_hit_at_all:
			continue
			
		# Generate a mesh from the 2 points
		# for now, owned by the current room's rendermesh
			
		#var mesh_pool = portal.other.room.get_mesh_pool(
			#portal.door_transform(Orientation.new(test_pos)).pos,
			#portal.door_transform(Orientation.new(min_ok_point)).pos,
			#portal.door_transform(Orientation.new(max_ok_point)).pos,
			#portal.other
		#)
		#
		#mesh_pools[portal.other.room] = MeshPool.combine([mesh_pools[portal.other.room], mesh_pool])

	#for room in mesh_pools:
		#room.render_mesh.set_mesh(mesh_pools[room].to_mesh(ArrayMesh.new()))
		
func get_visible_portal_range(portal: Portal) -> Array[Vector2]:
	if !portal.is_in_front(global_position):
		return []
			
	var start = portal.get_start()
	var end   = portal.get_end()
	var out_normal = portal.get_out_normal()
	var dir_to_end = portal.get_vec_along()
		
	# from you to the door-line
	var distance = (start - global_position).dot(out_normal)
	
	var test_pos = global_position
	
	if distance < 1:
		test_pos -= out_normal * (1 - distance)
		distance = 1
		
	var start_angle = rad_to_deg(global_position.angle_to_point(start))
	var end_angle = rad_to_deg(global_position.angle_to_point(end))
	
	if end_angle < start_angle:
		end_angle += 360
		
	var min_ok_angle = -1000000
	var min_ok_point = Vector2.ZERO
	var max_ok_angle = 1000000
	var max_ok_point = Vector2.ZERO
	
	var has_hit_at_all = false
	
	for current_angle in range(start_angle, end_angle, angle_increase):
		
		# https://forum.godotengine.org/t/how-to-get-a-portion-of-a-vector-that-is-aligned-with-another-vector/40426/4
		var direction = Vector2.from_angle(deg_to_rad(current_angle))
		
		var amount_along_normal = direction.dot(out_normal)
		# where on the door-line we test
		var hit_point = test_pos + direction * (distance / amount_along_normal)
		
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
				min_ok_angle = current_angle
				min_ok_point = hit_point
				
			max_ok_angle = current_angle
			max_ok_point = hit_point
			
	if !has_hit_at_all:
		return []
	
	return [min_ok_point, max_ok_point]
		
func _draw():
	if !(current_room and debug): return
	
	for portal in current_room.portals:
		var range = get_visible_portal_range(portal)
		
		if range.is_empty():
			draw_line(to_local(global_position), to_local(portal.global_position), Color.BLACK)
			return
		
		draw_line(to_local(global_position), to_local(range[0]), Color.BLUE)
		draw_line(to_local(global_position), to_local(range[1]), Color.BLUE)
		
		
			
func _input(event):
	gen_portals()
		#
#func _process(delta):
	#queue_redraw()
