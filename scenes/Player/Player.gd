extends SGKinematicBody2D

signal respawn_request

export var DEFAULT_HP := 100
export var RESPAWN_TIME := 5
var MASS := SGFixed.from_int(1000)
var SPEED := SGFixed.from_int(300)
var RUN_SPEED_SCALE := SGFixed.from_float(1.5)
var JUMP_SPEED := SGFixed.from_int(320)
var ACCEL_TIME := SGFixed.from_int(15)
var MAX_Y_LEVEL := SGFixed.from_int(2000)

onready var Anim = $AnimationTree
onready var AnimSprite = $AnimatedSprite
onready var Cam = $Camera2D
onready var BulletSpawn = $BulletSpawn
onready var HealthBar = $HealthBar
onready var BulletAudio = $Sounds/BulletSound
var BulletContainer: Node

var net_id: int

const Bullet = preload("res://scenes/Bullet/Bullet.tscn")

var username := "Player"
var kills := 0
var deaths := 0
var hp := DEFAULT_HP
var velocity := SGFixed.from_float_vector2(Vector2.ZERO)
var _is_on_floor := false

var dummy := false

var input_template := {
	'move': Vector2.ZERO,
	'shoot': false,
}


# Called when the node enters the scene tree for the first time.
func _ready():
	$RespawnTimer.wait_ticks = G.FPS*RESPAWN_TIME
	HealthBar.set_username(username)
	HealthBar.set_only_username(not net_id == get_tree().get_network_unique_id())
	
	SyncManager.connect("scene_spawned", self, "_on_scene_spawned")
	SyncManager.connect("scene_despawned", self, "_on_scene_despawned")

func _on_Bullet_hit() -> bool: # returns if the player has been hit
	if is_dead():
		return false
	take_damage(10)
	return true

func _on_bush_update():
	if net_id==get_tree().get_network_unique_id():return
	var in_bush := in_bush_count > 0
	if float(in_bush)!=HealthBar.modulate.a:return
	$Tween.interpolate_property(HealthBar, "modulate:a", int(in_bush), int(not in_bush), 0.6)
	$Tween.start()

var old_double_jumped := false
var has_double_jumped := false
var double_jumped := false
var old_input := input_template
func process_inputs(delta: int, input := {}) -> void:
	if input.move.x and (not input.shoot or not _is_on_floor):
		velocity.x = SGFixed.move_toward(velocity.x, SPEED*sign(input.move.x),ACCEL_TIME)
	else:
		velocity.x = SGFixed.move_toward(velocity.x, 0,SGFixed.mul(ACCEL_TIME,SGFixed.from_float(2-1.5*int(not _is_on_floor))))
	old_double_jumped = double_jumped
	if input.move.y>0:
		if _is_on_floor:  # or true to disable check
			double_jumped = false
			has_double_jumped = false
			
			#while AnimSprite.animation!="jump" or AnimSprite.frame!=3:
			#	yield(AnimSprite,"frame_changed")
			
			velocity.y = -JUMP_SPEED
		
		elif not double_jumped and not old_input.move.y>0 and not has_double_jumped:  # and false to yeet the code
			double_jumped = true
			velocity.y -= JUMP_SPEED
	elif input.move.y < 0:
		if not _is_on_floor:
			double_jumped = false
			has_double_jumped = true
		

func get_inputs() -> Dictionary:
	if dummy:
		return input_template
	var out: Dictionary
	out.move = Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"), Input.get_action_strength("up") - Input.get_action_strength("down"))
	out.shoot = bool(Input.is_action_pressed("shoot"))
	return out

# Should be called before updating position because of is_on_floor
func update_anim_state(input: Dictionary):
	if input.move.y > 0:
		Anim.set("parameters/in_air/current", 1)
	elif _is_on_floor and not (velocity.y < 0):
		Anim.set("parameters/in_air/current", 0)
		
	if input.move.x:
		Anim.set("parameters/movement/current", 1)
		AnimSprite.flip_h = input.move.x < 0
		BulletSpawn.fixed_position.x = abs(BulletSpawn.fixed_position_x) * sign(input.move.x)
	else:
		Anim.set("parameters/movement/current", 0)
		
	if double_jumped:
		Anim.set("parameters/has_jetpack/current", 1)
	else:
		Anim.set("parameters/has_jetpack/current", 0)
		
	if input.shoot:
		Anim.set("parameters/shoots/current", 1)
	else:
		Anim.set("parameters/shoots/current", 0)
		
	if is_dead():
		Anim.set("parameters/is_dead/current", 1)
	else:
		Anim.set("parameters/is_dead/current", 0)

func process_sounds(net_input: Dictionary):
	if G.MUTE:return
	if double_jumped and not old_double_jumped:
		$Sounds/Jetpack.play()
	# ONLY ONE SIDE
	if net_id != get_tree().get_network_unique_id():return

	if net_input.move.y > 0 and not old_input.move.y and _is_on_floor:
		$Sounds/Jump.play()
	

func handle_shooting(net_input: Dictionary):
	if net_input.shoot and not old_input.shoot and not $ShootTimer.ticks_left:
		$ShootTimer.wait_ticks = 4
		$ShootTimer.start()
		
	elif old_input.shoot and not net_input.shoot:
		$ShootTimer.stop()

func _on_ShootTimer_timeout():
	$ShootTimer.wait_ticks = 12
	spawn_bullet()
	

func spawn_bullet():
	SyncManager.spawn("Bullet", BulletContainer, Bullet, {
				player_id = net_id,
				fixed_position_x = fixed_position_x + BulletSpawn.fixed_position_x,
				fixed_position_y = fixed_position_y + BulletSpawn.fixed_position_y,
				fixed_rotation = SGFixed.PI*int(AnimSprite.flip_h),
				spawner_id = net_id
			})
	# AUDIO
	if not G.MUTE:
		BulletAudio.play()

func update_camera():
	var zoom := Vector2.ONE
	
func set_camera_current(current: bool):
	$Camera2D.current = current


func take_damage(damage: int):
	if is_dead():return
	hp = max(0, hp - damage)
	update_health_bar()
	if is_dead():
		_on_death()
	
	if not G.MUTE:
		$Sounds/Hurt.play()
	
	$Tween.interpolate_method(self, "set_flash_state", 0, 1, 0.1, Tween.TRANS_BOUNCE)
	$Tween.start()
	yield($Tween,"tween_completed")
	$Tween.interpolate_method(self, "set_flash_state", 1, 0, 0.1, Tween.TRANS_BOUNCE)
	$Tween.start()

func set_flash_state(state: float):
	AnimSprite.material.set_shader_param("flashState", state)

func update_health_bar():
	HealthBar.set_percent(float(hp) / float(DEFAULT_HP))

func is_dead() -> bool:
	return hp <= 0

func _on_death():
	if not $RespawnTimer.ticks_left:
		$RespawnTimer.start()
		deaths += 1

func _on_RespawnTimer_timeout():
	emit_signal("respawn_request", self)
	velocity = SGFixed.from_float_vector2(Vector2.ZERO)
	hp = DEFAULT_HP
	update_health_bar()

func _on_Bullet_hits_other_player(killer_id:int, victim_player):
	if victim_player.is_dead() and killer_id==net_id:
		kills += 1

func _on_game_end():
	dummy = true

"""
------------------------------------------------------------------------------
					NETWORK
------------------------------------------------------------------------------
"""
# LAG : udp and (udp.DstPort == 4444 or udp.SrcPort == 4444)

var FVector_UP := SGFixed.from_float_vector2(Vector2.UP)
func _network_process(net_input: Dictionary) -> void:
	if is_dead():
		net_input = input_template.duplicate()
	if net_input:
		process_inputs(G.DELTA, net_input)
		handle_shooting(net_input)
		update_anim_state(net_input)
		process_sounds(net_input)
		old_input = net_input.duplicate(true)
		if fixed_position_y > MAX_Y_LEVEL and not is_dead():
			hp = 0
			update_health_bar()
			_on_death()
	
	velocity.y += SGFixed.mul(SGFixed.mul(MASS,G.DELTA), SGFixed.from_float(1 - 0.6*int(double_jumped)))
	velocity = move_and_slide(velocity.mul(G.DELTA), FVector_UP).div(G.DELTA)
	_is_on_floor = is_on_floor()

func _interpolate_state_no_i_dont_want_that(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	if net_id == get_tree().get_network_unique_id():return
	fixed_position_x = lerp(old_state.fixed_position_x, new_state.fixed_position_x, weight)
	fixed_position_y = lerp(old_state.fixed_position_y, new_state.fixed_position_y, weight)

func _on_scene_spawned(name, spawned_node, scene, data):
	if name=="Bullet":
		spawned_node.connect("bullet_hit", self, "_on_Bullet_hits_other_player")
	
func _on_scene_despawned(name, spawned_node):
	if name=="Bullet":
		spawned_node.disconnect("bullet_hit", self, "_on_Bullet_hits_other_player")


func _get_local_input() -> Dictionary:
	return get_inputs()


func _save_state() -> Dictionary:
	return {
		fixed_position_x = fixed_position_x,
		fixed_position_y = fixed_position_y,
		old_input = old_input.duplicate(true),
		velocity_x = velocity.x,
		velocity_y = velocity.y,
		is_on_floor = is_on_floor(),
		double_jumped = double_jumped,
		has_double_jumped = has_double_jumped,
		hp = hp,
		kills = kills,
		deaths = deaths,
		dummy = dummy,
		in_bush_count = in_bush_count
	}

func _load_state(state: Dictionary) -> void:
	fixed_position.x = state.fixed_position_x
	fixed_position.y = state.fixed_position_y
	old_input = state.old_input.duplicate(true)
	velocity.x = state.velocity_x
	velocity.y = state.velocity_y
	_is_on_floor = state.is_on_floor
	double_jumped = state.double_jumped
	has_double_jumped = state.has_double_jumped
	hp = state.hp
	kills = state.kills
	deaths = state.deaths
	dummy = state.dummy
	in_bush_count = state.in_bush_count
	sync_to_physics_engine()





var in_bush_count := 0
func _on_BushDetector_area_entered(area: Area2D):
	if area.get_parent().has_method("helo_im_bush"):
		in_bush_count += 1
		_on_bush_update()


func _on_BushDetector_area_exited(area: Area2D):
	if area.get_parent().has_method("helo_im_bush"):
		_on_bush_update()
