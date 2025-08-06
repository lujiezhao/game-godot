class_name TextureSynchronizer
extends MultiplayerSynchronizer

# 专门用于texture同步的组件
# 支持texture URL同步和自动加载

signal texture_changed(texture_url: String, texture: Texture2D)

var texture_url: String = ""
var texture_hash: String = ""  # 用于检测texture是否发生变化
var is_loading: bool = false
var texture_cache: Dictionary = {}

func _ready() -> void:
	GameEvent.peer_connected.connect(_on_peer_connected)
	pass

# 设置texture URL并触发同步
func set_texture_url(url: String) -> void:
	if url == texture_url:
		return
	
	texture_url = url
	texture_hash = str(url.hash())  # 转换为字符串
	
	# 如果是authority，通知其他客户端
	if is_multiplayer_authority():
		update_texture_url.rpc(texture_url, texture_hash)

# RPC方法：更新texture URL
@rpc("authority", "call_local")
func update_texture_url(parm_url: String, parm_hash: String) -> void:
	texture_url = parm_url
	texture_hash = parm_hash
	_on_texture_url_changed()

# 当texture URL变化时的处理
func _on_texture_url_changed() -> void:
	if texture_url == "":
		return
	
	# 检查是否已缓存
	if texture_cache.has(texture_url):
		texture_changed.emit(texture_url, texture_cache[texture_url])
		return
	
	# 开始加载
	if not is_loading:
		is_loading = true
		load_texture_async(texture_url)

# 加载texture
func load_texture_async(img_url: String) -> void:
	if img_url == "":
		is_loading = false
		return
	
	var image_res = await Request._http_request_image(img_url.uri_decode())
	if image_res == null:
		is_loading = false
		return
	
	var image_data = image_res.image_data
	var texture = Utils.texture_from_bytes(image_data)
	
	if texture:
		# 缓存texture
		texture_cache[img_url] = texture
		texture_changed.emit(img_url, texture)
	
	is_loading = false

# 获取当前texture URL
func get_texture_url() -> String:
	return texture_url

# 检查是否正在加载
func is_texture_loading() -> bool:
	return is_loading

# 获取缓存的texture
func get_cached_texture(url: String) -> Texture2D:
	return texture_cache.get(url, null) 

func _on_peer_connected(id: int):
	update_texture_url.rpc_id(id, texture_url, texture_hash)
