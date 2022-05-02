extends Node

class_name ServerBrowser

signal new_server
signal remove_server

var socket_udp := PacketPeerUDP.new()
var listen_port = MG.BROADCAST_PORT
var known_servers := {}

var server_cleanup_time := 3

var browsing := false

func _ready():
	known_servers.clear()
	
func _process(delta):
	if not browsing:return
	if socket_udp.get_available_packet_count()>0:
		var server_ip = socket_udp.get_packet_ip()
		var server_port = socket_udp.get_packet_port()
		var bytes = socket_udp.get_packet()
		
		if server_ip!='' and server_port > 0:
			if not known_servers.has(server_ip):
				var server_message = bytes.get_string_from_ascii()
				var game_info = parse_json(server_message)
				game_info.ip = server_ip
				game_info.last_seen = OS.get_unix_time()
				known_servers[server_ip] = game_info
				emit_signal("new_server", game_info)
			else:
				known_servers[server_ip].last_seen = OS.get_unix_time()

func _on_clean_up():
	var now = OS.get_unix_time()
	for key in known_servers:
		if known_servers[key].last_seen + server_cleanup_time < now:
			emit_signal("remove_server", known_servers[key])
			known_servers.erase(key)
	yield(get_tree().create_timer(server_cleanup_time), "timeout")
	if browsing:
		_on_clean_up()

func start():
	browsing = true
	if socket_udp.listen(listen_port) != OK:
		print("ERROR : couldn't listen for servers on port " + str(listen_port))
		return
	_on_clean_up()

func stop():
	_exit_tree()

func _exit_tree():
	browsing = false
	socket_udp.close()
