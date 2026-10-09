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
	mesh.clear_surfaces()
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
	v3.y = neighbor.elevation * HexMetrics.ELEVATION_STEP
	v4.y = neighbor.elevation * HexMetrics.ELEVATION_STEP
	
	if cell.get_edge_type_in_direction(direction) == HexMetrics.HexEdgeType.Slope:
		triangulate_edge_terraces(v1, v2, cell, v3, v4, neighbor)
	else:
		add_quad(v1,v2,v3,v4)
		add_quad_colors(cell.color, cell.color, neighbor.color, neighbor.color)
	
#	TODO: Find a better null-coalescing approach for gdscript
	var next_neighbor = cell.get_neighbor(HexMetrics.next_direction(direction))
	if direction <= HexMetrics.HexDirection.E and next_neighbor:
		var v5 = v2 + HexMetrics.get_bridge(HexMetrics.next_direction(direction))
		v5.y = next_neighbor.elevation * HexMetrics.ELEVATION_STEP

		if cell.elevation <= neighbor.elevation:
			if cell.elevation <= next_neighbor.elevation:
				triangulate_corner(v2, cell, v4, neighbor, v5, next_neighbor)
			else:
				triangulate_corner(v5, next_neighbor, v2, cell, v4, neighbor)
		elif neighbor.elevation <= next_neighbor.elevation:
			triangulate_corner(v4, neighbor, v5, next_neighbor, v2, cell)
		else:
			triangulate_corner(v5, next_neighbor, v2, cell, v4, neighbor)
		add_triangle(v2,v4,v5)
		add_triangle_colors(cell.color, neighbor.color, next_neighbor.color)
	
func triangulate_edge_terraces(beginLeft, beginRight, beginCell, endLeft, endRight, endCell):
	var v3 = HexMetrics.terrace_lerp(beginLeft, endLeft, 1)
	var v4 = HexMetrics.terrace_lerp(beginRight, endRight, 1)
	var c2 = HexMetrics.terrace_color_lerp(beginCell.color, endCell.color, 1)

	add_quad(beginLeft, beginRight, v3, v4)
	add_quad_colors(beginCell.color ,beginCell.color, c2, c2)

	for i in range(2, HexMetrics.TERRACES_STEPS, 1):
		var v1 = v3
		var v2 = v4
		var c1 = c2
		v3 = HexMetrics.terrace_lerp(beginLeft, endLeft, i)
		v4 = HexMetrics.terrace_lerp(beginRight, endRight, i)
		c2 = HexMetrics.terrace_color_lerp(beginCell.color, endCell.color, i)
		add_quad(v1,v2,v3,v4)
		add_quad_colors(c1,c1,c2,c2)

	add_quad(v3, v4, endLeft, endRight)
	add_quad_colors(c2, c2, endCell.color, endCell.color)

func triangulate_corner(
	bottom:Vector3, bottomCell:HexCell, 
	left:Vector3, leftCell:HexCell, 
	right:Vector3, rightCell:HexCell
):
	var leftEdgeType = bottomCell.get_edge_type_with_cell(leftCell)
	var rightEdgeType = bottomCell.get_edge_type_with_cell(rightCell)

	if leftEdgeType == HexMetrics.HexEdgeType.Slope:
		if rightEdgeType == HexMetrics.HexEdgeType.Slope:
			triangulate_corner_terraces(bottom, bottomCell, left, leftCell, right, rightCell)
		elif rightEdgeType == HexMetrics.HexEdgeType.Flat:
			triangulate_corner_terraces(left, leftCell, right, rightCell, bottom, bottomCell)
		else:
			triangulate_corner_terraces_cliff(bottom, bottomCell, left, leftCell, right, rightCell)
	elif rightEdgeType == HexMetrics.HexEdgeType.Slope:
		if leftEdgeType == HexMetrics.HexEdgeType.Flat:
			triangulate_corner_terraces(right, rightCell, bottom, bottomCell, left, leftCell)
		else:
			triangulate_corner_cliff_terraces(bottom, bottomCell, left, leftCell, right, rightCell)
	elif leftCell.get_edge_type_with_cell(rightCell) == HexMetrics.HexEdgeType.Slope:
		if leftCell.elevation < rightCell.elevation:
			triangulate_corner_cliff_terraces(right, rightCell, bottom, bottomCell, left, leftCell)
		else:
			triangulate_corner_terraces_cliff(left, leftCell, right, rightCell, bottom, bottomCell)
	else:
		add_triangle(bottom,left,right)
		add_triangle_colors(bottomCell.color, leftCell.color, rightCell.color)

func triangulate_corner_terraces(
	begin:Vector3, beginCell:HexCell, 
	left:Vector3, leftCell:HexCell, 
	right:Vector3, rightCell:HexCell
):
		var v3 = HexMetrics.terrace_lerp(begin, left, 1)
		var v4 = HexMetrics.terrace_lerp(begin, right, 1)
		var c3 = HexMetrics.terrace_color_lerp(beginCell.color, leftCell.color, 1)
		var c4 = HexMetrics.terrace_color_lerp(beginCell.color, rightCell.color, 1)

		add_triangle(begin, v3, v4)
		add_triangle_colors(beginCell.color, c3, c4)

		for i in range(2, HexMetrics.TERRACES_STEPS, 1):
			var v1 = v3
			var v2 = v4
			var c1 = c3
			var c2 = c4

			v3 = HexMetrics.terrace_lerp(begin, left, i)
			v4 = HexMetrics.terrace_lerp(begin, right, i)
			c3 = HexMetrics.terrace_color_lerp(beginCell.color, leftCell.color, i)
			c4 = HexMetrics.terrace_color_lerp(beginCell.color, rightCell.color, i)
			add_quad(v1, v2, v3, v4)
			add_quad_colors(c1, c2, c3, c4)

		add_quad(v3, v4, left, right)
		add_quad_colors(c3, c4, leftCell.color, rightCell.color)

func triangulate_corner_terraces_cliff(
	begin:Vector3, beginCell:HexCell, 
	left:Vector3, leftCell:HexCell, 
	right:Vector3, rightCell:HexCell
):
		var b = 1.0 / (rightCell.elevation - beginCell.elevation)
		if b < 0:
			b = -b
		var boundary = lerp(begin, right, b)
		var boundaryColor = lerp(beginCell.color, rightCell.color, b)

		triangulate_boundary_triangle(begin, beginCell, left, leftCell, boundary, boundaryColor)

		if leftCell.get_edge_type_with_cell(rightCell) == HexMetrics.HexEdgeType.Slope:
			triangulate_boundary_triangle(left, leftCell, right, rightCell, boundary, boundaryColor)
		else:
			add_triangle(left, right, boundary)
			add_triangle_colors(leftCell.color, rightCell.color, boundaryColor)

func triangulate_corner_cliff_terraces(
	begin:Vector3, beginCell:HexCell, 
	left:Vector3, leftCell:HexCell, 
	right:Vector3, rightCell:HexCell
):
		var b = 1.0 / (leftCell.elevation - beginCell.elevation)
		if b < 0:
			b = -b
		var boundary = lerp(begin, left, b)
		var boundaryColor = lerp(beginCell.color, leftCell.color, b)

		triangulate_boundary_triangle(right, rightCell, begin, beginCell, boundary, boundaryColor)

		if leftCell.get_edge_type_with_cell(rightCell) == HexMetrics.HexEdgeType.Slope:
			triangulate_boundary_triangle(left, leftCell, right, rightCell, boundary, boundaryColor)
		else:
			add_triangle(left, right, boundary)
			add_triangle_colors(leftCell.color, rightCell.color, boundaryColor)


func triangulate_boundary_triangle(
	begin:Vector3, beginCell:HexCell, 
	left:Vector3, leftCell:HexCell, 
	boundary:Vector3, boundaryColor:Color
):
		var v2 = HexMetrics.terrace_lerp(begin, left, 1)
		var c2 = HexMetrics.terrace_color_lerp(beginCell.color, leftCell.color, 1)

		add_triangle(begin, v2, boundary)
		add_triangle_colors(beginCell.color, c2, boundaryColor)

		for i in range(2, HexMetrics.TERRACES_STEPS, 1):
			var v1 = v2
			var c1 = c2
			v2 = HexMetrics.terrace_lerp(begin, left, i)
			c2 = HexMetrics.terrace_color_lerp(beginCell.color, leftCell.color, i)
			add_triangle(v1, v2, boundary)
			add_triangle_colors(c1, c2, boundaryColor)

		add_triangle(v2, left, boundary)
		add_triangle_colors(c2, leftCell.color, boundaryColor)

func add_triangle(v1:Vector3, v2:Vector3, v3:Vector3):
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
			
