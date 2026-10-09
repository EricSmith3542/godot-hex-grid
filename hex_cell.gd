class_name HexCell
extends Node3D

var coordinates:HexCoordinates
var color:Color
var elevation:int:
	set(new_value):
		elevation = new_value
		position.y = elevation * HexMetrics.ELEVATION_STEP 

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

func get_edge_type_in_direction(direction:HexMetrics.HexDirection):
	return HexMetrics.get_edge_type(elevation, neighbors[int(direction)].elevation)
	
func get_edge_type_with_cell(otherCell:HexCell) -> HexMetrics.HexEdgeType:
	return HexMetrics.get_edge_type(elevation, otherCell.elevation)
