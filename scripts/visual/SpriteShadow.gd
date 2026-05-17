extends RefCounted
class_name SpriteShadow


static func add_pair(parent: Node, texture: Texture2D, shadow_offset: Vector2, shadow_alpha: float) -> Sprite2D:
	var shadow := Sprite2D.new()
	shadow.texture = texture
	shadow.position = shadow_offset
	shadow.modulate = Color(0.05, 0.08, 0.10, shadow_alpha)
	shadow.z_index = -1
	parent.add_child(shadow)

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.set_meta("shadow_node", shadow)
	sprite.set_meta("shadow_offset", shadow_offset)
	parent.add_child(sprite)
	return sprite


static func set_pair_scale(sprite: Sprite2D, scale_value: Vector2) -> void:
	sprite.scale = scale_value
	var shadow: Sprite2D = sprite.get_meta("shadow_node")
	shadow.scale = scale_value


static func set_pair_position(sprite: Sprite2D, position_value: Vector2) -> void:
	sprite.position = position_value
	var shadow: Sprite2D = sprite.get_meta("shadow_node")
	var shadow_offset: Vector2 = sprite.get_meta("shadow_offset")
	shadow.position = position_value + shadow_offset
