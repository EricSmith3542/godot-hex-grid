extends Node3D

signal cell_clicked(coordinates:HexCoordinates, color:Color)

var left_color : Color = Color.BLUE
var right_color : Color = Color.GREEN

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var intersection_point = (get_viewport().get_camera_3d() as DebugCamera).get_position_collision_point(event.position)
			if intersection_point:
				var coordinates = HexCoordinates.from_position(intersection_point)
				cell_clicked.emit(coordinates,left_color)
				print("clicked coordinate " + str(HexCoordinates.from_position(intersection_point)))
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var intersection_point = (get_viewport().get_camera_3d() as DebugCamera).get_position_collision_point(event.position)
			if intersection_point:
				var coordinates = HexCoordinates.from_position(intersection_point)
				cell_clicked.emit(coordinates,right_color)
				print("clicked coordinate " + str(HexCoordinates.from_position(intersection_point)))

func _on_color_changed(color: Color) -> void:
	self.left_color = color
