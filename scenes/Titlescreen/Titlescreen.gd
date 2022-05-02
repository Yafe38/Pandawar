extends Node2D


var Explosion = preload("res://scenes/Titlescreen/scenes/Explosion.tscn")

onready var StartButton = $CanvasLayer/Control/Button
onready var BackTextureAfter = $CanvasLayer/Control/TextureRect/After

# Called when the node enters the scene tree for the first time.
func _ready():
	if G.intro_played:
		BackTextureAfter.modulate.a = 1
		$Title.visible = true
		$Title.modulate.a = 1
		StartButton.modulate.a = 1
		StartButton.visible = true
		return
		
	randomize()
	$Reveal.play()
	yield(get_tree().create_timer(10.2),"timeout")
	$AnimationPlayer.play("enter")
	$Rocket.connect("boom", self, "_on_Rocket_hit")
	$Title.modulate.a = 0
	StartButton.modulate.a = 0
	BackTextureAfter.modulate.a = 0
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_Rocket_hit():
	for i in range(100):
		var explosion = Explosion.instance()
		$Explosions.add_child(explosion)
		explosion.position = Vector2(rand_range(0, get_viewport_rect().size.x), rand_range(0, get_viewport_rect().size.y))
	$FinalExplosion.play()
	yield(get_tree().create_timer(0.1),"timeout")
	$AnimationPlayer.play("yeet_player")
	$Tween.interpolate_property($Title, "modulate:a", 0, 1, 1, Tween.TRANS_SINE)
	$Tween.interpolate_property(BackTextureAfter, "modulate:a", 0, 1, 1, Tween.TRANS_SINE)
	$Tween.start()
	yield(get_tree().create_timer(2.5), "timeout")
	$Tween.interpolate_property(StartButton, "modulate:a", 0, 1, 1, Tween.TRANS_SINE)
	$Tween.start()
	G.intro_played = true
	yield(get_tree().create_timer(4.5), "timeout")
	var explosion = Explosion.instance()
	explosion.no_random = true
	$Explosions.add_child(explosion)
	explosion.position = $EndExplosionPos.position
	$FireSound.play()


func _on_StartButton_pressed():
	get_tree().change_scene("res://scenes/NetworkSetup/NetworkSetup.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("shoot"):
		$Reveal.stop()
		$AnimationPlayer.stop()
		$AnimationPlayer.play("RESET")
		_on_Rocket_hit()
