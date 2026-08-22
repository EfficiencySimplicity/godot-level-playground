class_name ViewMesh

## A mesh proxy for the specific purpose of being a viewplane
## the mesh data is stored in non-packed arrays for easy transformations
## and it generates an actual mesh on-demand,
## along with storing room and y-level info

# where the point is in world space
var vertices: Array = []
# each set of 3 numbers specifies a triangle
var triangles: Array = []
# the uv coordinates for the texture...
var uvs: Array = []

var room: PortalRoom
var y: int

var mesh

func _init(_vertices, _triangles, _uvs, _room, _y):
	vertices = _vertices
	triangles = _triangles
	uvs = _uvs
	room = _room
	y = _y
		
func get_mesh():
	if mesh: return mesh
	
	mesh = ArrayMesh.new()
		
	# https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/arraymesh.html#doc-arraymesh
	# https://www.dgp.toronto.edu/~ah/csc418/fall_2001/tut/ogl_draw.html
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	surface_array[Mesh.ARRAY_VERTEX] = PackedVector2Array(vertices)
	surface_array[Mesh.ARRAY_TEX_UV] = PackedVector2Array(uvs)
	surface_array[Mesh.ARRAY_INDEX] = PackedInt32Array(triangles)
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	return mesh
