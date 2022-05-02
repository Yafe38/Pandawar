extends CanvasLayer


onready var TimeLabel = $Control/TimeLabel
onready var ErrorLabel = $Control/ErrorPanel/MarginContainer/VBoxContainer/CenterContainer/Label
onready var EndgamePanel = $Control/EngamePanel
onready var ErrorPanel = $Control/ErrorPanel
onready var UsernameContainer = $Control/EngamePanel/MarginContainer/VBoxContainer/Containers/UsernameC
onready var KillsContainer = $Control/EngamePanel/MarginContainer/VBoxContainer/Containers/KillsC
onready var DeathsContainer = $Control/EngamePanel/MarginContainer/VBoxContainer/Containers/DeathsC
onready var LobbyButton = $Control/EngamePanel/MarginContainer/VBoxContainer/LobbyButton
onready var LagLabel = $Control/LagLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	LagLabel.visible = false
	EndgamePanel.visible = false
	ErrorPanel.visible = false
	LobbyButton.visible = is_network_master()


func set_time_left(time_second: int) -> void:
	TimeLabel.text = str(time_second/60)+":"+str(time_second%60)

func update_player_points(data: Array):
	for child in UsernameContainer.get_children() + KillsContainer.get_children() + DeathsContainer.get_children():
		child.queue_free()
	for player_data in data:
		instance_label(UsernameContainer, player_data.username)
		instance_label(KillsContainer, str(player_data.kills))
		instance_label(DeathsContainer, str(player_data.deaths))

func set_endgamePanel_visibility(visible: bool):
	EndgamePanel.visible = visible

func instance_label(parent: Node, text: String):
	var lbl = Label.new()
	lbl.text = text
	parent.add_child(lbl)

func _on_error(msg := ""):
	ErrorPanel.visible = true
	ErrorLabel.text = msg
	

func _on_LobbyButton_pressed():
	rpc("back_to_lobby")
	
remotesync func back_to_lobby():
	G.swoosh_to_lobby = true
	get_tree().change_scene("res://scenes/NetworkSetup/NetworkSetup.tscn")
	
