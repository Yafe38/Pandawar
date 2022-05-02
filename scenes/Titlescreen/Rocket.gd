extends AnimatedSprite

signal boom

export var vroom := false
export var speed := 100
export var target:NodePath

onready var Target = get_node(target)

func _ready():
	pass # Replace with function body.


func _process(delta):
	if not vroom:return
	position += Vector2.RIGHT.rotated(rotation)*speed*delta
	rotation -= 0.6*PI*delta
	
	while position.y > Target.position.y:
		yield(self, "frame_changed")
	
	queue_free()
	emit_signal("boom")
	
