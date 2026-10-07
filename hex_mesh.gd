class_name HexMesh
extends MeshInstance3D

#signal cell_clicked(coordinates:HexCoordinates)

var vertices : PackedVector3Array
var normals : PackedVector3Array
var colors : PackedColorArray

@onready var collision_shape = $StaticBody3D/CollisionShape3D

func triangulate(cells:Array[HexCell]):
	vertices.clear()
	normals.clear()
	colors.clear()
	for cell in cells:
		triangulate_cell(cell)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	collision_shape.shape = mesh.create_trimesh_shape()
	
func triangulate_cell(cell:HexCell):
	var center:Vector3 = cell.position
	for i in range(6):
		add_triangle(center, center + HexMetrics.CORNERS[i+1], center + HexMetrics.CORNERS[i])
		add_triangle_color(cell.color)
	
func add_triangle(v1:Vector3, v2:Vector3, v3:Vector3):
	vertices.append(v1)
	vertices.append(v2)
	vertices.append(v3)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	
func add_triangle_color(color:Color):
	for i in range(3):
		colors.append(color)

#
#func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#var intersection_point = (camera as DebugCamera).get_position_collision_point(event.position)
			#var coordinates = HexCoordinates.from_position(intersection_point)
			#cell_clicked.emit(coordinates)
			#print("clicked coordinate " + str(HexCoordinates.from_position(intersection_point)))
			
