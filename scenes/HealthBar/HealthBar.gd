extends Node2D

onready var default_scale := scale

func set_percent(percent: float):
	$Tween.interpolate_method(self, "set_percent_worker", $MeshInstance2D.material.get_shader_param("percent"), percent, 0.2, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "scale", scale, scale*1.2, 0.2, Tween.TRANS_BOUNCE)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	$Tween.interpolate_property(self, "scale", scale, default_scale, 0.2, Tween.TRANS_BOUNCE)
	$Tween.start()

func set_percent_worker(percent: float):
	$MeshInstance2D.material.set_shader_param("percent", percent)

func set_username(username:String):
	$Label.text = username
	
func set_only_username(only_username: bool):
	$MeshInstance2D.visible = not only_username
