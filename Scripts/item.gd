extends Node2D
var value : int
var base_points : int
var respawnable := true
var sprite_texture: String
var item_type: String
var item_key: String

signal destroyed(key: String, loc : Vector2)

func setup(i_key: String, item_data: Dictionary):
	item_type = item_data.get("type", "apple")
	value = item_data.get("value", 1)
	base_points = item_data.get("points", 100)
	respawnable = item_data.get("respawnable", true)
	item_key = i_key
	
	sprite_texture = item_data.get("sprite", null)

	if sprite_texture:
		$AnimatedSprite2D.play(sprite_texture)
	
func destroy():
	emit_signal("destroyed", item_key, position)
	queue_free()
	
