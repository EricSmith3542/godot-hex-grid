extends Node3D

signal cell_clicked(coordinates:HexCoordinates, color:Color)

var color : Color = Color.PURPLE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var intersection_point = (get_viewport().get_camera_3d() as DebugCamera).get_position_collision_point(event.position)
			if intersection_point:
				var coordinates = HexCoordinates.from_position(intersection_point)
				cell_clicked.emit(coordinates,color)
				print("clicked coordinate " + str(HexCoordinates.from_position(intersection_point)))

func _on_color_changed(color: Color) -> void:
	self.color = color
