class_name HexGrid
extends Node3D

const HEX_CELL_SCENE = preload("res://hex_cell.tscn")

@onready var mesh:HexMesh = $HexMesh

var width : int = 6
var height : int = 6

var cells : Array[HexCell] = []

func _ready() -> void:
	for z in range(height):
		for x in range(width):
			build_cell(x,z)
			
	mesh.triangulate(cells)

func build_cell(x:int, z:int):
	var cell:HexCell = HEX_CELL_SCENE.instantiate()
	cell.position.x = (x + z * 0.5 - z / 2) * HexMetrics.INNER_RADIUS * 2
	cell.position.z = z * HexMetrics.OUTER_RADIUS * 1.5
	cell.set_coordinate_label_text(str(z) + ":" + str(x))
	
	
	cells.append(cell)
	add_child(cell)
	
