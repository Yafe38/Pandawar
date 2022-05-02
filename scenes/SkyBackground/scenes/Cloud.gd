extends Sprite

var speed: float

func set_cloud(type: int):
	assert(type>=0 and type <9)
	region_rect.position = Vector2(type%3, type/3) * region_rect.size
