class_name HexMesh
extends Node3D

var vertices : Array[Vector3]
var triangles : Array[int]
@onready var meshInstance:MeshInstance3D = $MeshInstance3D

func triangulate(cells:Array[HexCell]):
	vertices.clear()
	triangles.clear()
	
	for cell in cells:
		triangulate_cell(cell)
		
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	add_child(m)
	
func triangulate_cell(cell:HexCell):
	var center:Vector3 = cell.position
	add_triangle(center, center + HexMetrics.CORNERS[0], center + HexMetrics.CORNERS[1])
	
func add_triangle(v1:Vector3, v2:Vector3, v3:Vector3):
	var vertIndex:int = vertices.size()
	vertices.append(v1)
	vertices.append(v2)
	vertices.append(v3)
	triangles.append(vertIndex)
	triangles.append(vertIndex + 1)
	triangles.append(vertIndex + 2)
	
