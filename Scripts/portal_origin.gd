extends Area2D

@export var current_room: RoomGenerator
@export var angle_increase: int = 5

func _on_area_entered(area: Area2D):
	if area is RoomGenerator:
		current_room = area
	
func gen_portals():
	if current_room == null:
		print("No current room to gen portals from!")
		return
		
	var global_mesh_pool = MeshPool.new()
		
	for door in current_room.doors:
		
		if !door.is_in_front(global_position):
			continue;
			
		var start_angle = rad_to_deg(global_position.angle_to_point(door.get_start()))
		var end_angle = rad_to_deg(global_position.angle_to_point(door.get_end()))
		# should be in door
		var dir_to_end = (door.get_end() - door.get_start()).normalized()
		# a vector straight out the door
		var out_normal = door.get_normal() * -1
		# from you to the door-line
		var distance = (door.get_start() - global_position).dot(out_normal)
		
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
			var hit_point = global_position + direction * (distance / amount_along_normal)
			
			var rcparams = PhysicsRayQueryParameters2D.create(
				global_position,
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
			
		var mesh_pool = door.other.room.get_mesh_pool(
			door.door_transform(Orientation.new(global_position)).pos,
			door.door_transform(Orientation.new(min_ok_point)).pos,
			door.door_transform(Orientation.new(max_ok_point)).pos,
			door.other
		)
		
		global_mesh_pool = MeshPool.combine([global_mesh_pool, mesh_pool])
		
		# TODO: remove this, it draws but one.
		break

	current_room.render_mesh.set_mesh(global_mesh_pool.to_mesh(ArrayMesh.new()))
		
		
func _draw():
	if current_room == null:
		print("No current room to gen portals from!")
		return
		
	var global_mesh_pool = MeshPool.new()
		
	for door in current_room.doors:
		
		if !door.is_in_front(global_position):
			continue;
			
		var start_angle = rad_to_deg(global_position.angle_to_point(door.get_start()))
		var end_angle = rad_to_deg(global_position.angle_to_point(door.get_end()))
		# should be in door
		var dir_to_end = (door.get_end() - door.get_start()).normalized()
		# a vector straight out the door
		var out_normal = door.get_normal() * -1
		# from you to the door-line
		var distance = (door.get_start() - global_position).dot(out_normal)
		
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
			var hit_point = global_position + direction * (distance / amount_along_normal)
			
			var rcparams = PhysicsRayQueryParameters2D.create(
				global_position,
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
			
		var mesh_pool = door.other.room.get_mesh_pool(
			door.door_transform(Orientation.new(global_position)).pos,
			door.door_transform(Orientation.new(min_ok_point)).pos,
			door.door_transform(Orientation.new(max_ok_point)).pos,
			door.other
		)
		
		global_mesh_pool = MeshPool.combine([global_mesh_pool, mesh_pool])
		
		draw_circle(to_local(min_ok_point), 15, Color.CHARTREUSE)
		draw_string(SystemFont.new(), to_local(min_ok_point), "MIN")
		draw_circle(to_local(max_ok_point), 15, Color.BROWN)
		draw_string(SystemFont.new(), to_local(max_ok_point), "MAX")
		draw_circle(to_local(global_position), 15, Color.RED)
		draw_string(SystemFont.new(), to_local(global_position), "SELF")
		
		var other_pos = door.door_transform(Orientation.new(global_position)).pos
		var min_pos = door.door_transform(Orientation.new(min_ok_point)).pos
		var max_pos = door.door_transform(Orientation.new(max_ok_point)).pos
		
		draw_circle(to_local(min_pos), 15, Color.CHARTREUSE)
		draw_string(SystemFont.new(), to_local(min_pos), "TRANSFORMED MIN")
		draw_circle(to_local(max_pos), 15, Color.BROWN)
		draw_string(SystemFont.new(), to_local(max_pos), "TRANSFORMED MAX")
		draw_circle(to_local(other_pos), 15, Color.RED)
		draw_string(SystemFont.new(), to_local(other_pos), "TRANSFORMED SELF")
		
		draw_circle(to_local(Utils.extend_to_rect_edge(
			current_room.room_bounds,
			min_pos + (min_pos - other_pos).normalized(),
			(min_pos - other_pos).normalized())),
			10,
			Color.DARK_BLUE)
		draw_circle(to_local(Utils.extend_to_rect_edge(
			current_room.room_bounds,
			max_pos + (max_pos - other_pos).normalized(),
			(max_pos - other_pos).normalized())),
			10,
			Color.DARK_BLUE)

		# TODO: remove this, it draws but one.
		break
		
	for i in range(global_mesh_pool.vertices.size()):
		draw_string(SystemFont.new(), to_local(global_mesh_pool.vertices[i]), str(i))
			
func _input(event):
	gen_portals()

func _process(delta):
	queue_redraw()
