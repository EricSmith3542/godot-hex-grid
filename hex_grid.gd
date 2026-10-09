class_name HexGrid
extends Node3D

@export var width : int = 6
@export var height : int = 6
@export var default_cell_color : Color = Color.WHITE
@export var touched_cell_color : Color = Color.REBECCA_PURPLE

const HEX_CELL_SCENE = preload("res://hex_cell.tscn")

@onready var mesh:HexMesh = $HexMesh
@onready var editor:HexGridEditor = $HexGridEditor

var cells : Array[HexCell] = []

func _ready() -> void:
	# get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	
	var i = 0
	for z in range(height):
		for x in range(width):
			build_cell(x,z,i)
			i += 1
			
	mesh.triangulate(cells)

func build_cell(x:int, z:int, i:int):
	var cell:HexCell = HEX_CELL_SCENE.instantiate()

	@warning_ignore("integer_division")
	cell.position.x = (x + z * 0.5 - z / 2) * HexMetrics.INNER_RADIUS * 2
	cell.position.z = z * HexMetrics.OUTER_RADIUS * 1.5
	cell.coordinates = HexCoordinates.from_offset_coordinates(x,z)
	cell.color = default_cell_color
	cell.set_coordinate_label_text(cell.coordinates.to_string_lines())
	
	connect_neighbors(x,z,i,cell)
	
	cells.append(cell)
	add_child(cell)
	
func connect_neighbors(x:int, z:int, i:int, cell:HexCell):
	if x > 0:
		cell.set_neighbor(HexMetrics.HexDirection.W, cells[i-1])
	if z > 0:
		if (z & 1) == 0:
			cell.set_neighbor(HexMetrics.HexDirection.SE, cells[i-width])
			if x > 0:
				cell.set_neighbor(HexMetrics.HexDirection.SW, cells[i - width - 1])
		else:
			cell.set_neighbor(HexMetrics.HexDirection.SW, cells[i-width])
			if x < width - 1:
				cell.set_neighbor(HexMetrics.HexDirection.SE, cells[i - width + 1])


func get_cell(coordinates: HexCoordinates) -> HexCell:
	@warning_ignore("integer_division")
	var cell_index = coordinates.X + coordinates.Z * width + coordinates.Z / 2
	return cells[cell_index]
	
func refresh():
	mesh.triangulate(cells)
