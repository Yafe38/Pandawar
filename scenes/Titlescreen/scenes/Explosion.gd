extends AnimatedSprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var no_random := false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	visible = false
	if not no_random:
		yield(get_tree().create_timer(randf()),"timeout")
	visible = true
	
	play("default")
	yield(self, "animation_finished")
	queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
