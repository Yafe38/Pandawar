extends Node

class_name ServerAdvertiser

var broadcast_interval := 1

var server_info: Dictionary

var socket_udp:PacketPeerUDP
var broadcast_port = MG.BROADCAST_PORT

var broadcasting := false

func start():
	if get_tree().is_network_server():
		broadcasting = true
		socket_udp = PacketPeerUDP.new()
		socket_udp.set_broadcast_enabled(true)
		socket_udp.set_dest_address("255.255.255.255", broadcast_port)
		_on_BroadcastTimer_timeout()

func stop():
	_exit_tree()

func _on_BroadcastTimer_timeout():
	var packet_message = to_json(server_info)
	var packet = packet_message.to_ascii()
	socket_udp.put_packet(packet)
	yield(get_tree().create_timer(broadcast_interval), "timeout")
	if broadcasting:
		_on_BroadcastTimer_timeout()

func _exit_tree():
	broadcasting = false
	if socket_udp != null:
		socket_udp.close()
