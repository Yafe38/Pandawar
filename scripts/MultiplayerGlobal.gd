extends Node


const DEFAULT_PORT := 4444
const BROADCAST_PORT := 6900

var selected_server_data := {
	"ip":"localhost",
	"port":DEFAULT_PORT,
}

var advertiser_server_info := {
	name = "PW server",
	description = "A Panda Par server",
	players = 1,
	port = DEFAULT_PORT
}

var server_data := {
	SEED = 69,
	game_length = 300
}

var user_data := {
	username = ""
}



var connected_clients := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	server_data.SEED = randi()


func reset_network():
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer := get_tree().network_peer
	if peer:
		peer.close_connection()
	
