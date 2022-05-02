extends CanvasLayer

var Cloud = preload("res://scenes/SkyBackground/scenes/Cloud.tscn")

onready var SkyRect = $TextureRect
onready var CloudsContainer = $Clouds

# Called when the node enters the scene tree for the first time.
func _ready():
	seed(MG.server_data.SEED)
	for _i in range(rand_range(10, 20)):
		var pos = Vector2(SkyRect.rect_size.y* randf(), SkyRect.rect_size.x*randf()/((randf()+1)*1.5)) - SkyRect.rect_position*Vector2(1, -1)
		var scale = randf() + 0.5
		spawn_cloud(pos, scale)

func _process(delta):
	update_clouds(delta)

func spawn_cloud(cloud_position: Vector2, scale: float):
	var new_cloud = Cloud.instance()
	CloudsContainer.add_child(new_cloud)
	new_cloud.speed = (randf()+0.1)*5
	new_cloud.set_cloud(randi()%9)
	new_cloud.position = cloud_position
	new_cloud.scale *= scale/2

func update_clouds(delta: float):
	for cloud in CloudsContainer.get_children():
		cloud.position.x -= cloud.speed*delta
		if cloud.position.x+cloud.get_rect().size.x*cloud.scale.x < SkyRect.rect_position.x:
			cloud.position.x = SkyRect.rect_position.x + SkyRect.rect_size.x + cloud.get_rect().size.x
