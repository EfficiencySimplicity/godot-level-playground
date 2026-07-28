class_name Placement

enum Side {Up = 0, Right = 1, Down = 2, Left = 3}

var position: Vector2i
var side: Placement.Side

func _init(_position: Vector2i, _side: Placement.Side = Side.Up):
	position = _position
	side = _side

func map_vector2(v: Vector2) -> Vector2:
	return v.rotated(deg_to_rad(side * 90)) + Vector2(position)
	
func map_vector2i(v: Vector2i) -> Vector2i:
	return Vector2i(map_vector2(Vector2(v)).round())
