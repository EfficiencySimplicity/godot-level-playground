class_name Placement

var position: Vector2i
var side: int

func _init(_position: Vector2i, _side: int = 1):
	position = _position
	side = _side
	
func map_vector2i(v: Vector2i) -> Vector2i:
	# say a vector of (2, -1)
	# meaning pointing up and right
	# and it is rotated
	if side == 1:
		# no rotation; (2, -1)
		return position + v
	elif side == 2:
		# pointing right; (1, 2)
		return position + Vector2i(-v.y, v.x)
	elif side == 3:
		# pointing down; (-2, 1)
		return position + Vector2i(-v.x, -v.y)
	else:
		# pointing left; (-1, -2)
		return position + Vector2i(v.y, -v.x)
