@tool
class_name HexGridEditor
extends Node3D

var left_color : Color = Color.BLUE
var right_color : Color = Color.GREEN

var active_elevation : int = 0

@onready var color_picker:ColorPickerButton = $CanvasLayer/MarginContainer/VFlowContainer/ColorPickerButton
@onready var elevation_number_text:Label = $CanvasLayer/MarginContainer/VFlowContainer/HSplitContainer/ElevationNumber

#This breaks the call-down signal-up paradigm which is generally best in Godot
#But doing this should save passing a bunch of data batck and forth through signals as edits
#Get more complex
@onready var grid : HexGrid = get_parent()

#Warn if parent is not a HexGrid
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	if !grid or not (grid is HexGrid):
		warnings.append("HexGridEditor must have a HexGrid as a parent")
	return warnings

func _ready() -> void:
	set_color_picker_button_color(left_color)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			print("down")
			set_elevation(active_elevation - HexMetrics.ELEVATION_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			print("up")
			set_elevation(active_elevation + HexMetrics.ELEVATION_STEP)
		else:
			var intersection_point = find_intersection_with_mesh(event.position)
			if intersection_point:
				var coordinates = HexCoordinates.from_position(intersection_point)
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					edit_cell(grid.get_cell(coordinates), left_color)
				elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
					edit_cell(grid.get_cell(coordinates), right_color)

func find_intersection_with_mesh(click_position:Vector2) -> Variant:
	return (get_viewport().get_camera_3d() as DebugCamera).get_position_collision_point(click_position)

func edit_cell(cell:HexCell, new_color:Color):
	cell.color = new_color
	cell.elevation = active_elevation
	grid.refresh()

func _on_color_changed(color: Color) -> void:
	self.left_color = color
	set_color_picker_button_color(color)

func set_color_picker_button_color(color:Color):
	color_picker.color = color

func set_elevation(new_elevation:float):
	active_elevation = int(new_elevation)
	elevation_number_text.text = str(active_elevation)
