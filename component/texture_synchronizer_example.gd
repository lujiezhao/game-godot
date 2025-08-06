# TextureSynchronizer使用示例
# 这个文件展示了如何在角色中使用TextureSynchronizer组件

extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var texture_synchronizer: Node = $texture_synchronizer

func _ready() -> void:
	# 连接TextureSynchronizer的信号
	if texture_synchronizer:
		texture_synchronizer.texture_changed.connect(_on_texture_changed)

# 当texture加载完成时的回调
func _on_texture_changed(texture_url: String, texture: Texture2D) -> void:
	print("Texture已加载: ", texture_url)
	sprite.texture = texture

# 设置texture URL的示例
func set_character_texture(url: String) -> void:
	if texture_synchronizer:
		texture_synchronizer.set_texture_url(url)

# 检查texture是否正在加载
func is_texture_loading() -> bool:
	if texture_synchronizer:
		return texture_synchronizer.is_texture_loading()
	return false

# 获取当前texture URL
func get_current_texture_url() -> String:
	if texture_synchronizer:
		return texture_synchronizer.get_texture_url()
	return ""

# 预加载texture的示例
func preload_texture(url: String) -> void:
	if texture_synchronizer:
		# 注意：这个版本的TextureSynchronizer没有preload方法
		# 但可以通过设置URL来触发加载
		texture_synchronizer.set_texture_url(url) 