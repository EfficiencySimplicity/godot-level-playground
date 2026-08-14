class_name Placement

enum Side {UP = 0, RIGHT = 1, DOWN = 2, LEFT = 3}

var pos: Vector2i
var side: Placement.Side

func _init(_pos: Vector2i, _side: Placement.Side = Side.UP):
	pos = _pos
	side = _side
	
func translate(v: Vector2i) -> Placement:
	pos += v
	return self
	
func rotate(v: int) -> Placement:
	side = ((side + v) % 4) as Placement.Side
	return self
	
func move_forwards(distance: int) -> Placement:
	return translate(Vector2.from_angle(side * 90).round() * distance)

# Because of this, pointing right is equivalent to Side.UP, maybe an issue...
func to_orientation(cell_size: int = 64):
	return Placement.new(pos * cell_size, side * 90)
	
func cell_center(cell_size: int = 64) -> Vector2:
	return Vector2(pos * cell_size) + Vector2(1, 1) * cell_size / 2

func map_vector2i(v: Vector2i) -> Vector2i:
	# imagining (1, -2) (pointing northeast)
	if side == Side.UP:# + (1, -2) (ne)
		return pos + v
	elif side == Side.RIGHT:# + (2, 1) (se)
		return pos + Vector2i(-v.y, v.x)
	elif side == Side.DOWN:# + (-1, 2) (sw)
		return pos + Vector2i(-v.x, -v.y)
	elif side == Side.LEFT:# + (-2, -1) (nw)
		return pos + Vector2i(v.y, -v.x)
	else:
		assert(false, "There was a BAD error; a Placement had a non-(0-3) side: " + str(side))
		return pos
		
func _to_string() -> String:
	return str(pos, " ", side)
