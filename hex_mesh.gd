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
	var edge = EdgeVertices.new(v1, v2)

	triangulate_edge_fan(center, edge, cell.color)
	
	if direction <= HexMetrics.HexDirection.SE:
		triangulate_connection(direction, cell, edge)
	
	##Fill in the triangle gaps
	#add_triangle(v1, center + HexMetrics.first_corner(direction), v3)
	#add_triangle_colors(cell.color, (cell.color + prev_neighbor.color + neighbor.color)/ 3.0, bridgeColor)
	#add_triangle(v2, v4, center + HexMetrics.second_corner(direction))
	#add_triangle_colors(cell.color, bridgeColor, (cell.color + next_neighbor.color + neighbor.color)/ 3.0)
	
func triangulate_connection(direction:HexMetrics.HexDirection, cell:HexCell, e1:EdgeVertices):
	var neighbor = cell.get_neighbor(direction)
	if !neighbor:
		return
		
	#Add quad that bridges the above triangle to the neighbor cell in the direction
	var bridge = HexMetrics.get_bridge(direction)
	bridge.y = neighbor.position.y - cell.position.y
	var e2 = EdgeVertices.new(e1.v1 + bridge, e1.v4 + bridge)

	if cell.get_edge_type_in_direction(direction) == HexMetrics.HexEdgeType.Slope:
		triangulate_edge_terraces(e1, cell, e2, neighbor)
	else:
		triangulate_edge_strip(e1, cell.color, e2, neighbor.color)
	
	var next_neighbor = cell.get_neighbor(HexMetrics.next_direction(direction))
	if direction <= HexMetrics.HexDirection.E and next_neighbor:
		var v5 = e1.v4 + HexMetrics.get_bridge(HexMetrics.next_direction(direction))
		v5.y = next_neighbor.position.y

		if cell.elevation <= neighbor.elevation:
			if cell.elevation <= next_neighbor.elevation:
				triangulate_corner(e1.v4, cell, e2.v4, neighbor, v5, next_neighbor)
			else:
				triangulate_corner(v5, next_neighbor, e1.v4, cell, e2.v4, neighbor)
		elif neighbor.elevation <= next_neighbor.elevation:
			triangulate_corner(e2.v4, neighbor, v5, next_neighbor, e1.v4, cell)
		else:
			triangulate_corner(v5, next_neighbor, e1.v4, cell, e2.v4, neighbor)
	
func triangulate_edge_fan(center:Vector3, edge:EdgeVertices, color:Color):
	add_triangle(center, edge.v1, edge.v2)
	add_triangle_color(color)
	add_triangle(center, edge.v2, edge.v3)
	add_triangle_color(color)
	add_triangle(center, edge.v3, edge.v4)
	add_triangle_color(color)

func triangulate_edge_strip(e1:EdgeVertices, c1:Color, e2:EdgeVertices, c2:Color):
	add_quad(e1.v1,e1.v2,e2.v1,e2.v2)
	add_quad_colors(c1,c1,c2,c2)
	add_quad(e1.v2, e1.v3, e2.v2, e2.v3)
	add_quad_colors(c1,c1,c2,c2)
	add_quad(e1.v3, e1.v4, e2.v3, e2.v4)
	add_quad_colors(c1,c1,c2,c2)

func triangulate_edge_terraces(begin:EdgeVertices, beginCell:HexCell, end:EdgeVertices, endCell:HexCell):
	var e2 = EdgeVertices.terrace_lerp(begin, end, 1)
	var c2 = HexMetrics.terrace_color_lerp(beginCell.color, endCell.color, 1)

	triangulate_edge_strip(begin, beginCell.color, e2, c2)
	for i in range(2, HexMetrics.TERRACES_STEPS, 1):
		var e1 = e2
		var c1 = c2
		e2 = EdgeVertices.terrace_lerp(begin, end, i)
		c2 = HexMetrics.terrace_color_lerp(beginCell.color, endCell.color, i)
		triangulate_edge_strip(e1,c1,e2,c2)
	triangulate_edge_strip(e2,c2,end,endCell.color)

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
		var boundary = lerp(perturb(begin), perturb(right), b)
		var boundaryColor = lerp(beginCell.color, rightCell.color, b)

		triangulate_boundary_triangle(begin, beginCell, left, leftCell, boundary, boundaryColor)

		if leftCell.get_edge_type_with_cell(rightCell) == HexMetrics.HexEdgeType.Slope:
			triangulate_boundary_triangle(left, leftCell, right, rightCell, boundary, boundaryColor)
		else:
			add_triangle_unperturbed(perturb(left), perturb(right), boundary)
			add_triangle_colors(leftCell.color, rightCell.color, boundaryColor)

func triangulate_corner_cliff_terraces(
	begin:Vector3, beginCell:HexCell, 
	left:Vector3, leftCell:HexCell, 
	right:Vector3, rightCell:HexCell
):
		var b = 1.0 / (leftCell.elevation - beginCell.elevation)
		if b < 0:
			b = -b
		var boundary = lerp(perturb(begin), perturb(left), b)
		var boundaryColor = lerp(beginCell.color, leftCell.color, b)

		triangulate_boundary_triangle(right, rightCell, begin, beginCell, boundary, boundaryColor)

		if leftCell.get_edge_type_with_cell(rightCell) == HexMetrics.HexEdgeType.Slope:
			triangulate_boundary_triangle(left, leftCell, right, rightCell, boundary, boundaryColor)
		else:
			add_triangle_unperturbed(perturb(left), perturb(right), boundary)
			add_triangle_colors(leftCell.color, rightCell.color, boundaryColor)


func triangulate_boundary_triangle(
	begin:Vector3, beginCell:HexCell, 
	left:Vector3, leftCell:HexCell, 
	boundary:Vector3, boundaryColor:Color
):
		var v2 = perturb(HexMetrics.terrace_lerp(begin, left, 1))
		var c2 = HexMetrics.terrace_color_lerp(beginCell.color, leftCell.color, 1)

		add_triangle_unperturbed(perturb(begin), v2, boundary)
		add_triangle_colors(beginCell.color, c2, boundaryColor)

		for i in range(2, HexMetrics.TERRACES_STEPS, 1):
			var v1 = v2
			var c1 = c2
			v2 = perturb(HexMetrics.terrace_lerp(begin, left, i))
			c2 = HexMetrics.terrace_color_lerp(beginCell.color, leftCell.color, i)
			add_triangle_unperturbed(v1, v2, boundary)
			add_triangle_colors(c1, c2, boundaryColor)

		add_triangle_unperturbed(v2, perturb(left), boundary)
		add_triangle_colors(c2, leftCell.color, boundaryColor)

func add_triangle(v1:Vector3, v2:Vector3, v3:Vector3):
	vertices.append(perturb(v3))
	vertices.append(perturb(v2))
	vertices.append(perturb(v1))
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)

func add_triangle_unperturbed(v1:Vector3, v2:Vector3, v3:Vector3):
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
	vertices.append(perturb(v1))
	vertices.append(perturb(v2))
	vertices.append(perturb(v3))
	vertices.append(perturb(v3))
	vertices.append(perturb(v2))
	vertices.append(perturb(v4))
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
			
func perturb(pos:Vector3):
	var sample:Vector4 = HexMetrics.sample_noise(pos)
	pos.x += (sample.x * 2.0 - 1.0) * HexMetrics.CELL_PERTURB_STRENGTH
	# pos.y += (sample.y * 2.0 - 1.0) * HexMetrics.CELL_PERTURB_STRENGTH
	pos.z += (sample.z * 2.0 - 1.0) * HexMetrics.CELL_PERTURB_STRENGTH
	return pos
