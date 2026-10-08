class_name HexMesh
extends MeshInstance3D

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
	for d in HexMetrics.HexDirection.values():
		triangulate_cell_in_direction(d, cell)

func triangulate_cell_in_direction(direction:HexMetrics.HexDirection, cell:HexCell):
	
	#Add a inner-triangle for the current cell in the given direction
	var center:Vector3 = cell.position
	var v1 = center + HexMetrics.first_solid_corner(direction)
	var v2 = center + HexMetrics.second_solid_corner(direction)
	
	add_triangle(center, v1, v2)
	add_triangle_color(cell.color)
	
	if direction <= HexMetrics.HexDirection.SE:
		triangulate_connection(direction, cell, v1, v2)
	
	##Fill in the triangle gaps
	#add_triangle(v1, center + HexMetrics.first_corner(direction), v3)
	#add_triangle_colors(cell.color, (cell.color + prev_neighbor.color + neighbor.color)/ 3.0, bridgeColor)
	#add_triangle(v2, v4, center + HexMetrics.second_corner(direction))
	#add_triangle_colors(cell.color, bridgeColor, (cell.color + next_neighbor.color + neighbor.color)/ 3.0)
	
func triangulate_connection(direction:HexMetrics.HexDirection, cell:HexCell, v1:Vector3, v2:Vector3):
	var neighbor = cell.get_neighbor(direction)
	if !neighbor:
		return
		
	#Add quad that bridges the above triangle to the neighbor cell in the direction
	var bridge = HexMetrics.get_bridge(direction)
	var v3 = v1 + bridge
	var v4 = v2 + bridge
	
	add_quad(v1,v2,v3,v4)
	add_quad_colors(cell.color,cell.color,neighbor.color,neighbor.color)
	
#	TODO: Find a better null-coalescing approach for gdscript
	var next_neighbor = cell.get_neighbor(HexMetrics.next_direction(direction))
	if direction <= HexMetrics.HexDirection.E and next_neighbor:
		add_triangle(v2,v4,v2 + HexMetrics.get_bridge(HexMetrics.next_direction(direction)))
		add_triangle_colors(cell.color, neighbor.color, next_neighbor.color)
	
	
	
	
	
func add_triangle(v1:Vector3, v2:Vector3, v3:Vector3):
	var vertexIndex = vertices.size()
	vertices.append(v3)
	vertices.append(v2)
	vertices.append(v1)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	
func add_triangle_color(color:Color):
	colors.append(color)
	colors.append(color)
	colors.append(color)
	
func add_triangle_colors(c1:Color,c2:Color,c3:Color):
	colors.append(c3)
	colors.append(c2)
	colors.append(c1)
	
func add_quad(v1:Vector3, v2:Vector3, v3:Vector3, v4:Vector3):
	var vertexIndex = vertices.size()
	vertices.append(v1)
	vertices.append(v2)
	vertices.append(v3)
	vertices.append(v3)
	vertices.append(v2)
	vertices.append(v4)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	
func add_quad_colors(c1:Color,c2:Color,c3:Color,c4:Color):
	colors.append(c1)
	colors.append(c2)
	colors.append(c3)
	colors.append(c3)
	colors.append(c2)
	colors.append(c4)

#
#func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#var intersection_point = (camera as DebugCamera).get_position_collision_point(event.position)
			#var coordinates = HexCoordinates.from_position(intersection_point)
			#cell_clicked.emit(coordinates)
			#print("clicked coordinate " + str(HexCoordinates.from_position(intersection_point)))
			
