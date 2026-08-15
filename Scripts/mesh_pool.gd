class_name MeshPool

# where the point is in world space
var vertices: PackedVector2Array = []
# each set of 3 numbers specifies a triangle
var triangles: PackedInt32Array = []
# the uv coordinates for the texture...
var uvs: PackedVector2Array = []

func _init(_vertices = null, _triangles = null, _uvs = null):
	if _vertices != null:
		vertices = _vertices
	if _triangles != null:
		triangles = _triangles
	if _uvs != null:
		uvs = _uvs
	

static func combine(pools: Array[MeshPool]) -> MeshPool:
	var glob_vertices: PackedVector2Array = []
	var glob_triangles: PackedInt32Array = []
	var glob_uvs: PackedVector2Array = []
	
	for mesh in pools:
		var index_offset = glob_vertices.size()
		# does not map! Make it map and then finally gen a simple rect from each door!
		glob_triangles.append_array(PackedInt32Array(Array(mesh.triangles).map(func(x): return x + index_offset)))
		glob_vertices.append_array(mesh.vertices)
		glob_uvs.append_array(mesh.uvs)

	return MeshPool.new(glob_vertices, glob_triangles, glob_uvs)
	
func to_mesh(mesh: ArrayMesh):
	if self.is_useless():
		print("Useless mesh, not creating!")
		return mesh
		
	# https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/arraymesh.html#doc-arraymesh
	# https://www.dgp.toronto.edu/~ah/csc418/fall_2001/tut/ogl_draw.html
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_INDEX] = triangles
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	# mesh.regen_normal_maps()
	
	return mesh
	
func is_useless():
	return vertices.size() == 0 or triangles.size() == 0
