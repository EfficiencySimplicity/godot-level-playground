class_name DoorPlacer extends ItemPlacer

@export var actual_door: Door

# Erase the Solids block under the door
func on_place(stack, map_stack, pos):
	# I am ashamed of this code.
	# We take the must-be-solids map
	# ttt
	# and make the middle false
	# tft
	# Then get offset and stamp it.
	var solids_stamp = stack.layers["MustBeSolids"].copy()
	solids_stamp.s(Vector2i(1, 0), false)
	print("Before")
	print(map_stack.layers["Solids"])
	solids_stamp.stamp_on(map_stack.layers["Solids"], stack.get_match_position(pos, solids_stamp))
	print("After")
	print(map_stack.layers["Solids"])

#func transform_pos(pos: Placement) -> Placement:
	#var rot = int(global_rotation_degrees / 90)
	#var other_rot = int(other.global_rotation_degrees / 90)
	#
	#return Placement.new(Vector2i(1, 1))
