class_name HexCoordinates

var X:int
var Z:int
var Y:int

func _init(x:int, z:int) -> void:
	X = x
	Z = z
	Y = -X - Z
	
static func from_offset_coordinates(x:int, z:int) -> HexCoordinates:
	return new(x-z/2,z)
	
static func from_position(pos:Vector3) -> HexCoordinates:
	var x = pos.x / (HexMetrics.INNER_RADIUS * 2)
	var y = -x
	
	var offset = pos.z / (HexMetrics.OUTER_RADIUS * 3)
	x -= offset
	y -= offset
	
	var i_x = roundi(x)
	var i_y = roundi(y)
	var i_z = roundi(-x-y)
	
#	Fix rounding error near hexagon edges by reconstructing largest rounding delta from other two coords
	if i_x + i_y + i_z != 0:
		var dX = abs(x - i_x)
		var dY = abs(y - i_y)
		var dZ = abs(-x - y - i_z)
		
		if dX > dY and dX > dZ:
			i_x = -i_y - i_z
		elif dZ > dY:
			i_z = -i_x - i_y
	
	return new(i_x, i_z)
	
func _to_string() -> String:
	return "("+str(X)+","+str(Y)+","+str(Z)+")"
	
func to_string_lines() -> String:
	return str(X)+"\n"+str(Y)+"\n"+str(Z)
