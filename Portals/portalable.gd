class_name Portable extends Node2D

## A Node2D that can be teleported between PortalRooms and tracks what room it's in

@export var current_room: PortalRoom

## Represents a movement; what room you end up in and where you end up in global space
class room_movement:
	var room: PortalRoom
	var ort: Orientation
	
	func _init(_room: PortalRoom, _ort: Orientation):
		room = _room
		ort = _ort

## Returns an Orientation where the rotation is actually the rotation *change* that needs be applied
func get_move(movement: Vector2):
	var end = global_position + movement
	for portal in current_room.portals.filter(func(x): return x.is_in_front(global_position) and not x.is_in_front(end)):
		var distance = portal.distance_to(global_position)
		
		var amount_along_normal = movement.dot(portal.get_out_normal())
		# where on the door-line the movement hits
		var hit_point = global_position + movement * (distance / amount_along_normal)
		
		if sign((hit_point - portal.get_start()).dot(hit_point - portal.get_end())) == -1:
			# we assume the move isn't long enough to go through another portal in the room you head into
			return room_movement.new(
				portal.other.room,
				Orientation.new(
					portal.port_pos(end),
					portal.rotation_change_through()
				)
			)
			
	return room_movement.new(current_room, Orientation.new(end, 0))
