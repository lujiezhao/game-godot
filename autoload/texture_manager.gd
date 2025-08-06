extends Node

# 全局Texture管理器
# 负责texture的缓存、加载和同步

signal texture_loaded(texture_url: String, texture: Texture2D)
signal texture_load_failed(texture_url: String)

var texture_cache: Dictionary = {}
var loading_textures: Dictionary = {}

# 加载texture，支持缓存
func load_texture_async(texture_url: String) -> Texture2D:
	if texture_url == "":
		return null
	
	# 检查缓存
	if texture_cache.has(texture_url):
		return texture_cache[texture_url]
	
	# 检查是否正在加载
	if loading_textures.has(texture_url):
		# 等待加载完成
		await texture_loaded
		return texture_cache.get(texture_url, null)
	
	# 开始加载
	loading_textures[texture_url] = true
	
	var image_res = await Request._http_request_image(texture_url.uri_decode())
	if image_res == null:
		loading_textures.erase(texture_url)
		texture_load_failed.emit(texture_url)
		return null
	
	var image_data = image_res.image_data
	var texture = Utils.texture_from_bytes(image_data)
	
	if texture:
		texture_cache[texture_url] = texture
		texture_loaded.emit(texture_url, texture)
	else:
		texture_load_failed.emit(texture_url)
	
	loading_textures.erase(texture_url)
	return texture

# 预加载texture
func preload_texture(texture_url: String) -> void:
	if texture_url == "" or texture_cache.has(texture_url) or loading_textures.has(texture_url):
		return
	
	load_texture_async(texture_url)

# 清理缓存
func clear_cache() -> void:
	texture_cache.clear()
	loading_textures.clear()

# 获取缓存大小
func get_cache_size() -> int:
	return texture_cache.size()

# 检查texture是否已缓存
func is_texture_cached(texture_url: String) -> bool:
	return texture_cache.has(texture_url)

# 获取texture（如果已缓存）
func get_cached_texture(texture_url: String) -> Texture2D:
	return texture_cache.get(texture_url, null) 