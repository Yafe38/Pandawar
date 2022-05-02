extends Node


var shapes := []

func _ready():
	get_tree().connect("node_added", self, "_on_new_Node_update")


func _on_new_Node_update(node: Node):
	if node.is_in_group("sg_tilemap"):
		add_SGCollisions(node)
		
func add_SGCollisions(tilemap: TileMap):
	var tileset := tilemap.tile_set
	var instance_count := 0
	for cell_coord in tilemap.get_used_cells():
		var cell_id := tilemap.get_cell(cell_coord.x, cell_coord.y)
		var cell_tile_coord = tilemap.get_cell_autotile_coord(cell_coord.x, cell_coord.y)
		if not tileset.tile_get_shape_count(cell_id):continue
		for shape in tileset.tile_get_shapes(cell_id):
			if shape.autotile_coord == cell_tile_coord:
				add_SGStaticBody(shape.shape, cell_coord, tilemap)
				instance_count += 1
	print("Created ",instance_count, " SGStaticBody(s) for Tilemap ",tilemap)
			
func add_SGStaticBody(shape: ConvexPolygonShape2D, coord: Vector2, tilemap: TileMap):
	var SG_static_body := SGStaticBody2D.new()
	var SG_collision_poly := SGCollisionPolygon2D.new()
	
	SG_collision_poly.polygon = shape.points
	
	tilemap.add_child(SG_static_body)
	SG_static_body.add_child(SG_collision_poly)
	SG_static_body.fixed_position = SGFixed.from_float_vector2(coord * tilemap.cell_size)

