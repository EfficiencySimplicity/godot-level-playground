class_name Utils

static func get_bounds(xs: Array, f: Callable) -> Rect2:
	return xs.reduce(func(rect, x): return rect.merge(f.call(x)), f.call(xs[0]))

static func shape_bounding_rect(shape: CollisionShape2D) -> Rect2:
	return Rect2i(Vector2i(shape.global_position - shape.shape.size / 2), shape.shape.size)
