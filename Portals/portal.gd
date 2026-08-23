@tool
class_name Portal extends Node2D

## The Portal class is basically just a plane that connects to another Portal,
## And handles transforms between the two.
## A Portable queries the Portals in the room it's in to manage teleportation
## A PortalOrigin uses the Portals in the room it's in to collect and render out ViewMeshes

## The PortalRoom this Portal belongs to
@export var room: PortalRoom
## The Portal this one links to
@export var other: Portal

## The width of the Portal; independent of any actual scaling in-game
@export var width: float:
	set(v):
		width = v
		queue_redraw()

@export var debug: bool:
	set(v):
		debug = v
		queue_redraw()

# TODO: this can happen in the getter / setter
## Conects this portal to another; setting the 'other' property of each.
func connect_portal(_other: Portal):
	other = _other
	other.other = self

# https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html
func _draw():
	if !debug: return
	
	# https://www.reddit.com/r/godot/comments/9aaejq/how_do_i_draw_in_global_coordinates_from_a_node2d/
	# https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-draw-set-transform
	draw_set_transform_matrix(global_transform.affine_inverse())
	
	if other:
		var c = Color.LIGHT_PINK
		c.a = .5
		draw_line(global_position, other.global_position, c, 2)
		draw_circle(global_position, 5, c)
	
	draw_circle(get_start(), 3, Color.AZURE)
	draw_circle(get_end(), 3, Color.AZURE)
	draw_line(get_start(), get_end(), Color.WHITE)
	
	var line_end = global_position + get_normal() * 16
	draw_line(global_position, line_end, Color.WHITE)
	draw_circle(line_end, 3, Color.AZURE)

## Takes an Orientation and transforms it through the portal
func port(orientation: Orientation) -> Orientation:
	var relative_pos = orientation.pos - global_position
	# https://github.com/godotengine/godot-proposals/discussions/9996
	var rot_difference = rotation_change_through()
	var new = Orientation.new(other.global_position, rot_difference).map_vector2(relative_pos)
	return Orientation.new(new, orientation.rot + rot_difference)
	
## Takes a Vector2 and transforms it through the portal
func port_pos(pos: Vector2) -> Vector2:
	return Orientation.new(other.global_position, rotation_change_through()).map_vector2(pos - self.global_position)

## Is this point in front of the portal? Points right on the portal are considered behind it.
## This doesn't take width into account; the portal is considered an infinite line
## splitting the world in twain
func is_in_front(pos: Vector2):
	return Vector2.from_angle(global_rotation + deg_to_rad(90)).dot(pos - global_position) > 0

## A normalized vector pointing 'forwards' out of the portal; When is_in_front() is true,
## that means this vector is pointing roughly at you
func get_normal():
	return Vector2.from_angle(deg_to_rad(global_rotation_degrees + 90))
	
## A normalized vector pointing 'out' of the portal; when you are walking towards a portal,
## you are walking in roughly the same direction as this vector
func get_out_normal():
	return get_normal() * -1

## The distance from a point to the portal; this imagines the portal as an infinite line
## and the distance is to the nearest point on that line. 
## If you are behind the portal, the distance is negative.	
func distance_to(point: Vector2) -> float:
	return (get_start() - point).dot(get_out_normal())

## Gets a point and a direction and finds where the point will hit the portal
## if it continues in that direction. It imagines the portal as an infinite line.
## Allows you to pass on extra arguments so you can cache 'em yourself.
func cast_on(point: Vector2, dir: Vector2, distance = null, distance_along_self = null) -> Vector2:
	if !distance: distance = distance_to(point)
	if !distance_along_self: distance_along_self = dir.dot(get_out_normal())
	return point + dir * (distance / distance_along_self)

## Gets a normalized vector from the start of the portal to the end; 
## if your portal is a door, the direction from the hinges to the handle (assuming the door's closed).
func get_vec_along():
	return (get_end() - get_start()).normalized()
	
## The starting point of the portal; if your portal is a door, the side where the hinges are
func get_start():
	return global_position - (Vector2.from_angle(global_rotation) * (width / 2) * .99)

## The ending point of the portal; if your portal is a door, the side where the handle is
func get_end():
	return global_position + (Vector2.from_angle(global_rotation) * (width / 2) * .99)
	
## If you walk through the portal, this is how many degrees you'll have to turn 
## to be facing the same direction relative to the portal you come out of
func rotation_change_through():
	return fmod((other.global_rotation_degrees + 180) - global_rotation_degrees, 360)
