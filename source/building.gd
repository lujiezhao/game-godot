class_name Building
extends Node2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready():
	pass

func set_texture(img_url: StringName) -> void:
	#sprite_2d.set("texture", img_url)
	#print(img_url)
	if !img_url:
		return
	var image_res = await Request._http_request_image(img_url.uri_decode())
	if image_res == null:
		return
	var image_data = image_res.image_data
	var texture = Utils.texture_from_bytes(image_data)
	if texture:
		sprite_2d.texture = texture
