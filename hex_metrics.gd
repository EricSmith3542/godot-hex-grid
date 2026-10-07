#This class stores metrics about the hexagons that populate the hex grid. These metrics can be used to control the size and shape of the hexagon tiles
class_name HexMetrics

#The radius of the circle that contains that vertices of the hexagon
const OUTER_RADIUS : float = 10.0
#The radius of the circle that contains the center of each edge
const INNER_RADIUS : float =  OUTER_RADIUS * 0.866025404 #Outer radius * sqrt(3)/2 = inner radius

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
