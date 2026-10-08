#This class stores metrics about the hexagons that populate the hex grid. These metrics can be used to control the size and shape of the hexagon tiles
class_name HexMetrics

enum HexDirection {NE, E, SE, SW, W, NW}

#The radius of the circle that contains that vertices of the hexagon
const OUTER_RADIUS : float = 10.0
#The radius of the circle that contains the center of each edge
const INNER_RADIUS : float =  OUTER_RADIUS * 0.866025404 #Outer radius * sqrt(3)/2 = inner radius

const SOLID_FACTOR : float = 0.75
const BLEND_FACTOR : float = 1.0 - SOLID_FACTOR

#The 3D coordinates of the 6 vertices for a hexagon centered on 0,0,0
#These corners use the XZ-plane as the floor
#The seventh element is the same as the first to avoid OOB exceptions when generating triangles
const CORNERS = [
	Vector3(0.0, 0.0, OUTER_RADIUS),
	Vector3(INNER_RADIUS, 0.0, 0.5 * OUTER_RADIUS),
	Vector3(INNER_RADIUS, 0.0, -0.5 * OUTER_RADIUS),
	Vector3(0.0, 0.0, -OUTER_RADIUS),
	Vector3(-INNER_RADIUS, 0.0, -0.5 * OUTER_RADIUS),
	Vector3(-INNER_RADIUS, 0.0, 0.5 * OUTER_RADIUS),
	Vector3(0.0, 0.0, OUTER_RADIUS),
]

static func opposite_direction(direction:HexDirection) -> HexDirection:
	if int(direction) < 3:
		return (int(direction) + 3) as HexDirection
	return (int(direction) - 3) as HexDirection
	
static func next_direction(direction:HexDirection) -> HexDirection:
	return HexDirection.NE if direction == HexDirection.NW else (direction + 1) as HexDirection
	
static func previous_direction(direction:HexDirection) -> HexDirection:
	return HexDirection.NW if direction == HexDirection.NE else (direction - 1) as HexDirection


static func first_corner(direction:HexDirection) -> Vector3:
	return CORNERS[int(direction)]
static func second_corner(direction:HexDirection) -> Vector3:
	return CORNERS[int(direction)+1]
	
static func first_solid_corner(direction:HexDirection) -> Vector3:
	return CORNERS[int(direction)] * SOLID_FACTOR
static func second_solid_corner(direction:HexDirection) -> Vector3:
	return CORNERS[int(direction)+1] * SOLID_FACTOR
	
static func get_bridge(direction:HexDirection) -> Vector3:
	return (CORNERS[int(direction)] + CORNERS[int(direction) + 1]) * 0.5 * BLEND_FACTOR
