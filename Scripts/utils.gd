class_name Utils

static func get_bounds(xs: Array, f: Callable) -> Rect2:
	return xs.reduce(func(rect, x): return rect.merge(f.call(x)), f.call(xs[0]))

static func shape_bounding_rect(shape: CollisionShape2D) -> Rect2:
	return Rect2i(Vector2i(shape.global_position - shape.shape.size / 2), shape.shape.size)

static func get_corners(rect: Rect2) -> Array:
	# hey, these are in clockwise order!
	return [
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y)
	]

# along the shortest distance between the two, is b > a?
static func compare_angles(a: float, b: float):
	var i = 0
	while abs(a - b) > 180 and i < 100:
		if a > b:
			b += 360
		else:
			a += 360
	if i == 100:
		print("Fuse (in angle comparison) blew!")
		
	return b > a
	
static func test_angle_comparisons():
	assert(compare_angles(1, 10) == true)
	assert(compare_angles(1, 100) == true)
	assert(compare_angles(170, -170) == true)
	assert(compare_angles(200, -140) == true)
	assert(compare_angles(-170, -140) == true)
	assert(compare_angles(200, 230) == true)
	assert(compare_angles(10, 1) == false)
	assert(compare_angles(100, 1) == false)
	assert(compare_angles(-170, 170) == false)
	assert(compare_angles(-140, 200) == false)
	assert(compare_angles(-140, -170) == false)
	assert(compare_angles(230, 200) == false)
	#assert(false)
	
static func safediv(a, b):
	return INT32_MAX if is_zero_approx(b) else a/b
	
# assumes the pos is within the rect
# will only consider hitting edges, but also end up in corners just fine!
static func extend_to_rect_edge(rect: Rect2, pos: Vector2, dir: Vector2):
	var left_dist  = rect.position.x - pos.x
	var up_dist    = rect.position.y - pos.y
	var right_dist = rect.position.x + rect.size.x - pos.x
	var down_dist  = rect.position.y + rect.size.y - pos.y
	
	# number of times needed to reach left edge
	var left_mul = safediv(left_dist, dir.x)
	var right_mul = safediv(right_dist, dir.x)
	var up_mul = safediv(up_dist, dir.y)
	var down_mul = safediv(down_dist, dir.y)
	
	# only consider positive muls!
	
	var muls = [left_mul, right_mul, up_mul, down_mul].filter(func(x): return x >= 0)
	if muls.size() == 0:
		print(rect, " ", [left_mul, right_mul, up_mul, down_mul], " ", pos, " ", dir)
	return pos + muls.min() * dir
	
		
		
