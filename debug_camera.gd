class_name DebugCamera
extends Camera3D

@export var ray_length = 1000.0

func get_position_collision_point(pos:Vector2) -> Variant:
	var ray_origin = project_ray_origin(pos)
	var ray_end = ray_origin + project_ray_normal(pos) * ray_length
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	#SET COLLISION MASK HERE TO FILTER FOR ONLY CERTAIN OBJECTS
	#query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	if result:
		return result["position"]
	return null	
