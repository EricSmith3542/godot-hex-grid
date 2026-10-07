class_name HexMesh
extends MeshInstance3D

var vertices : PackedVector3Array
var normals : PackedVector3Array

func triangulate(cells:Array[HexCell]):
	vertices.clear()
	for cell in cells:
		triangulate_cell(cell)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
	
func triangulate_cell(cell:HexCell):
	var center:Vector3 = cell.position
	for i in range(6):
		add_triangle(center, center + HexMetrics.CORNERS[i], center + HexMetrics.CORNERS[i+1])
	
func add_triangle(v1:Vector3, v2:Vector3, v3:Vector3):
	var vertIndex:int = vertices.size()
	vertices.append(v1)
	vertices.append(v2)
	vertices.append(v3)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	
