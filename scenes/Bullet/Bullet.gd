extends SGArea2D

signal bullet_hit

export var lifetime_sec := 5

var SPEED := SGFixed.from_int(600)

onready var LifetimeTimer = $LifetimeTimer

var spawn_player_id: int
var damage := 10

func _network_spawn(data: Dictionary) -> void:
	spawn_player_id = data.player_id
	fixed_position.x = data.fixed_position_x
	fixed_position.y = data.fixed_position_y
	fixed_rotation = data.fixed_rotation
	spawn_player_id = data.spawner_id
	LifetimeTimer.wait_ticks = G.FPS*lifetime_sec
	LifetimeTimer.start()
	sync_to_physics_engine()

func _network_despawn() -> void:
	LifetimeTimer.stop()

func _network_process(_input: Dictionary) -> void:
	fixed_position.iadd(SGFixed.from_float_vector2(Vector2.RIGHT).rotated(fixed_rotation).mul(SPEED).mul(G.DELTA))
	sync_to_physics_engine()
	check_collision()

func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	fixed_position_x = lerp(old_state.fixed_position_x, new_state.fixed_position_x, weight)
	fixed_position_y = lerp(old_state.fixed_position_y, new_state.fixed_position_y, weight)
	

func _save_state() -> Dictionary:
	var state = {
		fixed_position_x = fixed_position_x,
		fixed_position_y = fixed_position_y,
		fixed_rotation = fixed_rotation
	}
	return state

func _load_state(state: Dictionary) -> void:
	fixed_position_x = state.fixed_position_x
	fixed_position_y = state.fixed_position_y
	fixed_rotation = state.fixed_rotation
	sync_to_physics_engine()
"""
func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	Utils.interpolate_node_transform_state(self, old_state, new_state, weight)
"""

func can_hit(body: SGCollisionObject2D) -> bool:
	return true

func check_collision() -> void:
	for body in get_overlapping_bodies():
		_on_bullet_collision(body)

func _on_bullet_collision(body: SGCollisionObject2D) -> void:
	if is_queued_for_deletion() or not is_inside_tree():
		return

	if not can_hit(body):
		return
	
	if body.has_method("_on_Bullet_hit"):
		if not body._on_Bullet_hit():
			return
		emit_signal("bullet_hit", spawn_player_id, body)
	
	SyncManager.despawn(self)
	LifetimeTimer.stop()

func _on_LifetimeTimer_timeout() -> void:
	SyncManager.despawn(self)
	LifetimeTimer.stop()

