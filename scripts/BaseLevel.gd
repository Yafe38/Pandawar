extends Node2D

export var player_spawns_path:NodePath
export var player_container_path:NodePath
export var bullet_container_path: NodePath
export var game_timer_path:NodePath
export var player_HUD_path:NodePath
	
var Player = preload("res://scenes/Player/Player.tscn")

const LOG_FILE_DIRECTORY := "user://detailed_logs"
var logging_enabled := G.DEBUG and true

onready var PlayerSpawns = get_node(player_spawns_path)
onready var PlayerContainer = get_node(player_container_path)
onready var GameTimer = get_node(game_timer_path)
onready var PlayerHUD = get_node(player_HUD_path)

func _ready():
	seed(MG.server_data.SEED)
	instance_net_players()
	
	if logging_enabled:
		start_logging()
		
	SyncManager.connect("sync_lost", self, "_on_sync_lost")
	SyncManager.connect("sync_regained", self, "_on_sync_regained")
	SyncManager.connect("sync_stopped", self, "_on_sync_stopped")
	SyncManager.connect("sync_error", self, "_on_sync_error")
	GameTimer.wait_ticks = MG.server_data.game_length*G.FPS
	GameTimer.one_shot = true
	GameTimer.start()
	GameTimer.connect("timeout", self, "_on_gameTimer_timeout")
	
	_update_game_time_HUD()
	
func _update_game_time_HUD():
	PlayerHUD.set_time_left(GameTimer.ticks_left/G.FPS)
	yield(get_tree().create_timer(0.5), "timeout")
	_update_game_time_HUD()
	
func instance_net_players():
	var player_queue := []
	player_queue.append(1)
	if not get_tree().is_network_server():
		player_queue.append(get_tree().get_network_unique_id())
	for id in SyncManager.peers.keys():
		if id != 1:
			player_queue.append(id)
	player_queue.sort()
	var i := 0
	var SpawnPositions = PlayerSpawns.get_children()
	SpawnPositions.shuffle()
	for player_id in player_queue:
		instance_player(player_id, SpawnPositions[i%PlayerSpawns.get_child_count()].fixed_position)
		i+=1

func find_spawn_pos(player: SGKinematicBody2D) -> SGFixedVector2:
	var best_pos: SGFixedVector2
	var best_score := -1
	for Position2d in PlayerSpawns.get_children():
		var score := find_spawn_pos_score_compute(Position2d.fixed_position, player)
		if score > best_score:
			best_pos = Position2d.fixed_position
			best_score = score
	
	return best_pos

func find_spawn_pos_score_compute(fixed_position: SGFixedVector2, player_filter: SGKinematicBody2D) -> int:
	var out := 0
	for player in PlayerContainer.get_children():
		if player_filter==player:continue
		out += fixed_position.distance_to(player.fixed_position)
	
	return out

func instance_player(net_id:int, spawn_pos: SGFixedVector2):
	#print(get_tree().get_network_unique_id(), " -> Instancing : ", net_id)
	var player = Player.instance()
	player.name = "Player"+str(net_id)
	player.username = MG.connected_clients[str(net_id)].username
	player.net_id = net_id
	PlayerContainer.add_child(player)
	player.BulletContainer = get_node(bullet_container_path)
	player.set_network_master(net_id)
	player.fixed_position = spawn_pos
	player.sync_to_physics_engine()
	player.set_camera_current(net_id==get_tree().get_network_unique_id())
	player.connect("respawn_request", self, "_on_Player_respawn_request")

func _on_Player_respawn_request(player: SGKinematicBody2D):
	player.fixed_position = find_spawn_pos(player)
	player.sync_to_physics_engine()

func start_logging():
	var dir = Directory.new()
	if not dir.dir_exists(LOG_FILE_DIRECTORY):
		dir.make_dir(LOG_FILE_DIRECTORY)
	
	var datetime = OS.get_datetime(true)
	var log_file_name = "%04d%02d%02d-%02d%02d%02d-peer-%d.log" % [
		datetime.year,
		datetime.month,
		datetime.day,
		datetime.hour,
		datetime.minute,
		datetime.second,
		get_tree().get_network_unique_id()
	]
	
	SyncManager.start_logging(LOG_FILE_DIRECTORY + "/" + log_file_name)
	
func _on_sync_stopped():
	SyncManager.stop_logging()

func _on_sync_lost():
	PlayerHUD.LagLabel.visible = true
	
func _on_sync_regained():
	PlayerHUD.LagLabel.visible = false
	
func _on_sync_error(msg: String):
	SyncManager.stop()
	PlayerHUD._on_error(msg)
	

func pause_players() -> void:
	for player in PlayerContainer.get_children():
		player._on_game_end()

func get_players_score_data() -> Array:
	var out: Array
	for player in PlayerContainer.get_children():
		out.append({
			username = player.username,
			kills = player.kills,
			deaths = player.deaths
		})
	return out
	
func sort_players_kill_data(data: Array) -> Array:
	var out = data.duplicate(true)
	out.sort_custom(self, "sort_player_kill_compare")
	return out
	

func sort_player_kill_compare(data1: Dictionary, data2: Dictionary) -> bool:
	return float(data1.kills)/(data1.deaths+1.0)>float(data2.kills)/(data2.deaths+1.0)


func _on_gameTimer_timeout():
	pause_players()
	PlayerHUD.update_player_points(sort_players_kill_data(get_players_score_data()))
	PlayerHUD.set_endgamePanel_visibility(true)
	SyncManager.stop()
