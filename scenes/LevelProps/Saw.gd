extends SGArea2D

export var point_A_path: NodePath
export var point_B_path: NodePath
export var travel_time := 5
export var damage := 100


onready var PointA = get_node(point_A_path).fixed_position
onready var PointB = get_node(point_B_path).fixed_position
onready var travel_vector = PointB.sub(PointA)
onready var travel_vector_part = travel_vector.mul(G.DELTA).div(SGFixed.from_int(travel_time))

var way := 1
var tick := 0.0

func _ready():
	fixed_position = PointA

func _network_process(_input: Dictionary) -> void:
	fixed_position.x += travel_vector_part.x * way
	fixed_position.y += travel_vector_part.y * way
	sync_to_physics_engine()
	check_collision()
	
	tick += 1
	if tick/float(G.FPS) > travel_time:
		way *= -1
		tick = 0

func check_collision() -> void:
	var ovelapping = get_overlapping_bodies()
	for body in ovelapping:
		_on_body_collision(body)

func _on_body_collision(body: SGCollisionObject2D) -> void:

	
	if body.has_method("take_damage"):
		body.take_damage(damage)
			

func _save_state() -> Dictionary:
	var state = {
		fixed_position_x = fixed_position_x,
		fixed_position_y = fixed_position_y,
		way = way,
		tick = tick,
	}
	return state

func _load_state(state: Dictionary) -> void:
	fixed_position_x = state.fixed_position_x
	fixed_position_y = state.fixed_position_y
	way = state.way
	tick = state.tick
	sync_to_physics_engine()
