class_name HexCell
extends Node3D

var coordinates:HexCoordinates
var color:Color

var neighbors:Array[HexCell]

func _init() -> void:
	neighbors.resize(6)

func set_coordinate_label_text(text:String):
	$CoordinateLabel.text = text
	
func get_neighbor(direction:HexMetrics.HexDirection) -> HexCell:
	return neighbors[int(direction)]
	
func set_neighbor(direction:HexMetrics.HexDirection, cell:HexCell):
	neighbors[int(direction)] = cell
	cell.neighbors[int(HexMetrics.opposite_direction(direction))] = self
	
