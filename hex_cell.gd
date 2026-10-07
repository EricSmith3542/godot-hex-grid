class_name HexCell
extends Node3D

var coordinates:HexCoordinates
var color:Color

func set_coordinate_label_text(text:String):
	$CoordinateLabel.text = text
