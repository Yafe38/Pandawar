extends "res://scripts/BaseLevel.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
func _ready():
	print("My tileset has ",len($Tilemap.get_used_cells()), " used cells")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
