extends Control

var ServerAdvertiser = preload("res://scripts/ServerAdvertiser.gd")
var ServerBrowser = preload("res://scripts/ServerBrowser.gd")

onready var Message = $MessageLabel
onready var StartButton = $TabContainer/Lobby/HBoxContainer/Left/HBoxContainer/StartButton
onready var CliServerIp = $"TabContainer/Join server/VBoxContainer/Manual/ServerIp/LineEdit"
onready var CliServerPort = $"TabContainer/Join server/VBoxContainer/Manual/ServerPort/LineEdit"
onready var CliUsernameInput = $"TabContainer/Join server/VBoxContainer/Manual/Connect/LineEdit"
onready var SrvServerPort = $"TabContainer/Host server/VBoxContainer/GridContainer/PortInput"
onready var SrvNameInput = $"TabContainer/Host server/VBoxContainer/GridContainer/NameInput"
onready var SrvDescInput = $"TabContainer/Host server/VBoxContainer/GridContainer/DescInput"
onready var SrvUsernameInput = $"TabContainer/Host server/VBoxContainer/GridContainer/UsernameInput"
onready var GLOptionButton = $"TabContainer/Host server/VBoxContainer/GridContainer/GLOptionButton"
onready var InputPanel = $TabContainer
onready var ServerNamesContainer = $"TabContainer/Join server/VBoxContainer/Browser/ServerName/Names"
onready var ServerDescContainer = $"TabContainer/Join server/VBoxContainer/Browser/ServerDesc/Descriptions"
onready var ServerPlayerCountContainer = $"TabContainer/Join server/VBoxContainer/Browser/NbPlayers/PlayerCounts"
onready var LobbyPlayerContainer = $TabContainer/Lobby/HBoxContainer/Left/Players/MarginContainer/ScrollContainer/PlayerContainer

onready var ChatTextInput = $TabContainer/Lobby/HBoxContainer/Chat/HBoxContainer/TextEdit
onready var ChatText = $TabContainer/Lobby/HBoxContainer/Chat/Panel/MarginContainer/ScrollContainer/RichTextLabel

onready var Advertiser = $ServerAdvertiser
onready var Browser = $ServerBrowser

var game_lengths = {
	"5 minutes":5*60,
	"10 minutes":10*60,
	"20 minutes":20*60,
	"30 minutes":30*60,
	"1 hour":60*60
}


func _ready():
	randomize()
	if G.DEBUG:
		CliServerIp.text = "localhost"
	
	CliServerPort.text = str(MG.DEFAULT_PORT)
	SrvServerPort.text = str(MG.DEFAULT_PORT)
	InputPanel.set_tab_hidden(2, true)
	StartButton.disabled = true
	set_round_OptionButton()
		
	
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	SyncManager.connect("sync_started", self, "_on_sync_started")
	SyncManager.connect("sync_stopped", self, "_on_sync_stopped")
	
	if G.swoosh_to_lobby:
		G.swoosh_to_lobby = false
		if is_network_master():
			get_tree().network_peer.refuse_new_connections = false
			Advertiser.server_info = MG.advertiser_server_info
			Advertiser.start()
			StartButton.disabled = false
		switch_to_Lobby()
		return
		
	
	Browser.connect("new_server", self, "_on_new_server")
	Browser.connect("remove_server", self, "_on_server_remove")
	Browser.start()

func set_round_OptionButton():
	if G.DEBUG:
		game_lengths["DEBUG"] = 30
	for txt in game_lengths.keys():
		GLOptionButton.add_item(txt)

func _on_Host_pressed():
	var peer := NetworkedMultiplayerENet.new()
	peer.create_server(int(SrvServerPort.text), 69)
	get_tree().network_peer = peer
	Message.text = "Waiting for players..."
	
	Browser.stop()
	MG.advertiser_server_info ={
		name = SrvNameInput.text,
		description = SrvDescInput.text,
		players = 1,
		port = int(SrvServerPort.text)
	}
	Advertiser.server_info = MG.advertiser_server_info
	Advertiser.start()
	
	if not SrvUsernameInput.text:
		MG.user_data.username = "Player-"+str(randi()%10000)
	else:
		MG.user_data.username  = SrvUsernameInput.text
	
	MG.connected_clients = {
		"1":MG.user_data
	}
	MG.server_data.game_length = game_lengths.values()[GLOptionButton.selected]
	
	StartButton.disabled = false
	switch_to_Lobby()

func _on_Join_pressed():
	if G.DEBUG:
		G.MUTE = true
	if not CliUsernameInput.text:
		MG.user_data.username = "Player-"+str(randi()%10000)
	else:
		MG.user_data.username  = CliUsernameInput.text
	MG.selected_server_data.ip = CliServerIp.text
	MG.selected_server_data.port = int(CliServerPort.text)
	
	var peer := NetworkedMultiplayerENet.new()
	peer.create_client(MG.selected_server_data.ip, MG.selected_server_data.port)
	get_tree().network_peer = peer
	
	StartButton.disabled = true
	Message.text = "Connecting..."

func _on_new_server(info: Dictionary):
	update_known_servers()
	
func _on_server_remove(info: Dictionary):
	update_known_servers()

func update_known_servers():
	for index in ServerNamesContainer.get_child_count():
		ServerNamesContainer.get_child(index).queue_free()
		ServerDescContainer.get_child(index).queue_free()
		ServerPlayerCountContainer.get_child(index).queue_free()
	for server_info in Browser.known_servers.values():
		instance_label(ServerNamesContainer, server_info.name)
		instance_label(ServerDescContainer, server_info.description)
		instance_label(ServerPlayerCountContainer, str(server_info.players))
		
func instance_label(parent: Node, text: String):
	var lbl = Label.new()
	lbl.text = text
	parent.add_child(lbl)

onready var old_cli_server_port_txt = CliServerPort.text
func _on_CliPort_text_changed(new_text: String):
	control_lineEdit_is_int(CliServerPort, old_cli_server_port_txt)
	old_cli_server_port_txt = CliServerPort.text

onready var old_srv_server_port_txt = SrvServerPort.text
func _on_SrvServerPort_text_changed(new_text):
	control_lineEdit_is_int(SrvServerPort, old_srv_server_port_txt)
	old_srv_server_port_txt = SrvServerPort.text

func control_lineEdit_is_int(node: LineEdit, old_text: String):
	if not node.text.is_valid_integer():
		var caret_back = node.caret_position
		var bad_text = node.text
		node.text = old_text
		node.caret_position = caret_back + (len(old_text)-len(bad_text))



func _on_Browser_gui_input(event):
	if event is InputEventMouseButton and not event.pressed:
		for index in range(ServerNamesContainer.get_child_count()):
			if is_pos_in_node(ServerNamesContainer.get_child(index), event.global_position) or is_pos_in_node(ServerDescContainer.get_child(index), event.global_position) or is_pos_in_node(ServerPlayerCountContainer.get_child(index), event.global_position):
				var server_info = Browser.known_servers.values()[index]
				CliServerIp.text = server_info.ip
				CliServerPort.text = str(server_info.port)


func is_pos_in_node(node: Control, position: Vector2) -> bool:
	return Rect2(node.rect_global_position, node.rect_size).has_point(position)


"""
------------------------------------------------------
				LOBBY
------------------------------------------------------
"""

func switch_to_Lobby():
	InputPanel.set_tab_hidden(0, true)
	InputPanel.set_tab_hidden(1, true)
	InputPanel.set_tab_hidden(2, false)
	
	update_player_list()

func update_player_list():
	for child in LobbyPlayerContainer.get_children():
		child.queue_free()
	for player in MG.connected_clients.values():
		instance_label(LobbyPlayerContainer, player.username)

func _on_StartButton_pressed():
	if is_network_master():
		get_tree().network_peer.refuse_new_connections = true
		Message.text = "Starting sync"
		randomize()
		rpc("set_map", G.Maps[randi()%G.Maps.size()])
		yield(get_tree().create_timer(2),"timeout")
		SyncManager.start()
		Advertiser.stop()
		StartButton.visible = false

func _on_connected_to_server():
	Message.text ="Connected to server"
	rpc_id(1, "send_user_data", to_json(MG.user_data))
	Browser.stop()
	switch_to_Lobby()

func _on_server_disconnected():
	Message.text = "Disconnected from server"

func _on_network_peer_connected(id: int):
	if not is_network_master():return
	Message.text = "Client "+str(id)+" joined"
	MG.connected_clients[str(id)] = {}
	MG.advertiser_server_info.players = MG.connected_clients.size()
	Advertiser.server_info = MG.advertiser_server_info
	rpc_id(id, "set_network_peers", to_json(MG.connected_clients))
	
func _on_network_peer_disconnected(id: int):
	Message.text = "Client "+str(id)+" left"
	MG.connected_clients.erase(str(id))
	SyncManager.remove_peer(id)

func _on_sync_started():
	Message.text = "Synced"
	get_tree().change_scene(G.current_map)
	
func _on_sync_stopped():
	Message.text = "Sync stopped"

remotesync func set_map(map: String):
	G.current_map = map

remote func send_user_data(data_str: String):
	if not is_network_master():return
	MG.connected_clients[str(get_tree().get_rpc_sender_id())] = parse_json(data_str)
	rpc("set_server_data",to_json({
			clients = MG.connected_clients,
			server_data = MG.server_data
		}))

remotesync func set_server_data(data_str: String):
	var data = parse_json(data_str)
	MG.connected_clients = data.clients
	MG.server_data = data.server_data
	SyncManager.clear_peers()
	for id in MG.connected_clients.keys():
		if int(id)!=get_tree().get_network_unique_id():
			SyncManager.add_peer(int(id))
		else:
			MG.connected_clients[id] = MG.user_data
	update_player_list()
	
"""
------------------------------------------------------
				CHAT
------------------------------------------------------
"""


func _on_Chat_submit():
	var text = ChatTextInput.text
	if not text:
		return
	rpc("_on_net_chat", text)
	ChatTextInput.text = ""
	
remotesync func _on_net_chat(message: String):
	var username = MG.connected_clients[str(get_tree().get_rpc_sender_id())].username
	ChatText.bbcode_text += "[color=yellow]"+username+" : [/color]"+message+"\n"






func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://scenes/Titlescreen/Titlescreen.tscn")
		
