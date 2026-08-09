class_name Orientation
## The non-grid version of Placement

var pos: Vector2
var rot: float

func _init(_pos: Vector2 = Vector2(0, 0), _rot: float = 0):
	pos = _pos
	rot = _rot
	
func translate(v: Vector2) -> Orientation:
	pos += v
	return self
	
func rotate(v: float) -> Orientation:
	rot += v
	return self
	
func move_forwards(distance: float) -> Orientation:
	return translate(Vector2.from_angle(deg_to_rad(rot)) * distance)
	
func to_placement(cell_size: int = 64):
	return Placement.new(floor(pos / cell_size), int(rot / 90))

func map_vector2(v: Vector2) -> Vector2:
	return v.rotated(deg_to_rad(rot)) + Vector2(pos)

static func from_object(object: Node2D) -> Orientation:
	return Orientation.new(object.global_position, object.global_rotation_degrees)
	
func apply_to_object(object: Node2D):
	object.global_position = pos
	object.global_rotation_degrees = rot
	
func _to_string() -> String:
	return str(pos, " ", rot, "°")
