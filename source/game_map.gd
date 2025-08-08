class_name GameMap
extends Node2D

var MAP_LAYER = preload("uid://bu3s00aih1ef4")

# 配置常量 - 根据实际服务器调整
const REMOTE_JSON_PATH = "https://game-node-server-prod-1089107932175.us-central1.run.app/game/roominfo/"
var remote_json_url = ""
const TILE_SIZE = 16

# 资源缓存目录
var GAME_CACHE_ROOT = Config.GAME_CACHE_ROOT
var CACHE_DIR: String = ""
var TILESET_CACHE_DIR: String = ""
var CACHE_VERSION_FILE: String = ""

var map_container: Node2D  # 地图容器节点
var http_request: HTTPRequest
var layers_to_load = []  # 待处理图层队列
var current_layer_index = -1  # 当前处理的图层索引
var tileset: TileSet  # TileSet资源
var tileset_texture: Texture2D  # 图块集纹理
var tileset_loaded = false  # 图块集是否已加载完成

# 缓存版本控制
var current_cache_version: String = ""
var server_cache_version: String = ""

# 新增：多图块集支持
var tilesets_data: Array = []  # 存储所有图块集数据
var tileset_textures: Dictionary = {}  # 存储每个图块集的纹理 {tileset_index: texture}
var tileset_sources: Dictionary = {}  # 存储每个图块集的源ID {tileset_index: source_id}
var tilesets_loaded_count = 0  # 已加载的图块集数量
var total_tilesets = 0  # 总图块集数量
var tileset_requests: Array = []  # 待加载的图块集请求队列
var current_tileset_request_index = 0  # 当前处理的图块集请求索引

# 新增：碰撞系统支持
var collision_tiles: Dictionary = {}  # 存储有碰撞属性的图块 {tileset_index: {tile_id: collision_type}}
var collision_layers: Array = []  # 存储碰撞图层

# 已有的碰撞层，从数据中获取的地图数据如果是碰撞层，则在这个层复制已有的图块到相应的位置
@onready var collision_tileMapLayer = $TileMapLayer

#导航层
@onready var nav_layer: TileMapLayer = $NavLayer

@onready var game_id = $"..".game_id

@onready var game_id_timer: Timer = $game_id_timer


# 通知数据加载完成，调整镜头limit
signal set_camera_limit(tile_width: int, tile_height: int)

# 游戏数据准备完成通知
signal init_game_data(game_data)

#地图数据初始化完成信号
signal game_map_ready

func _ready():
	game_id_timer.timeout.connect(on_game_id_timeout)
	
	game_id_timer.start()

func on_game_id_timeout():
	game_id = owner.game_id
	if game_id == "":
		return
	# 初始化缓存目录
	initialize_cache_directories()
	game_id_timer.stop()

# 初始化缓存目录
func initialize_cache_directories():
	# 确保游戏ID不为空
	if game_id.is_empty():
		push_error("game_id为空，无法初始化缓存目录")
		return
	
	# 构建缓存路径
	var game_cache_dir = GAME_CACHE_ROOT.path_join(game_id)
	CACHE_DIR = game_cache_dir.path_join("map_cache")
	TILESET_CACHE_DIR = game_cache_dir.path_join("tileset_cache")
	CACHE_VERSION_FILE = game_cache_dir.path_join("cache_version.json")
	
	# 创建目录结构
	DirAccess.make_dir_absolute(GAME_CACHE_ROOT)
	DirAccess.make_dir_absolute(game_cache_dir)
	DirAccess.make_dir_absolute(CACHE_DIR)
	DirAccess.make_dir_absolute(TILESET_CACHE_DIR)
	
	#print("缓存目录初始化完成")
	#print("游戏ID: ", game_id)
	#print("游戏缓存目录: ", game_cache_dir)
	
	# 加载当前缓存版本
	await load_cache_version()
	
	# 创建TileSet资源
	tileset = TileSet.new()
	
	# 启动加载流程
	#load_remote_map()
	load_game_data()

func load_remote_map():
	print("开始加载远程地图: ", remote_json_url)
	#http_request.request(remote_json_url)
	var jsonRes = await Request._http_get(remote_json_url)
	var game_json_res = jsonRes
	if !game_json_res:
		return
	GameCatch.save_game_json(JSON.stringify(game_json_res), game_id)
	process_game_data(game_json_res)

func process_game_data(game_data):
	init_game_data.emit(game_data)
	var map_data = game_data.map_data
	var game_info = game_data.game_info
	
	# 检查缓存版本
	server_cache_version = game_info.get("updated_at", "")
	if server_cache_version.is_empty():
		print("警告：服务器响应中没有updated_at字段")
	else:
		print("服务器缓存版本: ", server_cache_version)
		print("本地缓存版本: ", current_cache_version)
		
		# 如果版本不匹配，清理缓存
		if current_cache_version != server_cache_version:
			print("缓存版本不匹配，清理缓存并重新加载")
			clear_all_cache()
			# 更新本地缓存版本
			current_cache_version = server_cache_version
			save_cache_version()
	
	if !map_data:
		return
	set_camera_limit.emit(map_data.width * map_data.tilewidth, map_data.height * map_data.tileheight)
	
	# 确保所需字段存在
	if not map_data.has("tilesets") or not map_data.has("layers"):
		push_error("地图数据格式错误")
		return
	
	# 处理图块集
	_process_tilesets(map_data["tilesets"])
	
	# 准备图层加载队列
	layers_to_load = map_data["layers"]
	current_layer_index = 0
	
	# 如果所有图块集已加载，立即开始加载图层
	if tilesets_loaded_count >= total_tilesets:
		_load_next_layer()

# 处理下一个图层 - 使用TileMap节点（修复渲染问题）
func _load_next_layer():
	if current_layer_index >= layers_to_load.size():
		game_map_ready.emit()
		return
	
	# 验证所有图块集是否已加载
	if not _verify_tilesets_loaded():
		print("等待图块集加载完成...")
		call_deferred("_load_next_layer")
		return
	
	var layer_data = layers_to_load[current_layer_index]
	
	if layer_data["type"] != "tilelayer":
		#print("跳过非瓦片图层: " + layer_data["name"])
		current_layer_index += 1
		call_deferred("_load_next_layer")
		return
	
	# 检查是否是碰撞图层
	var is_collision_layer = _is_collision_layer(layer_data)
	var is_cover_layer = _is_cover_layer(layer_data)
	
	if is_collision_layer:
		# 碰撞图层：绘制到静态的tileMapLayer中
		_draw_collision_layer_to_static_tilemap(layer_data)
	elif is_cover_layer:
		_draw_collision_layer_to_static_tilemap(layer_data, Vector2i(0, 2))
	else:
		# 普通图层：创建新的TileMap节点
		_create_dynamic_tilemap_layer(layer_data)
	
	# 处理下一个图层
	current_layer_index += 1
	call_deferred("_load_next_layer")

# 验证所有图块集是否已加载
func _verify_tilesets_loaded() -> bool:
	if tilesets_loaded_count < total_tilesets:
		print("图块集加载进度: ", tilesets_loaded_count, "/", total_tilesets)
		return false
	
	# 检查每个图块集是否都有对应的纹理和源
	for i in range(tilesets_data.size()):
		if not tileset_textures.has(i):
			print("缺少图块集 ", i, " 的纹理")
			return false
		if not tileset_sources.has(i):
			print("缺少图块集 ", i, " 的源ID")
			return false
	
	#print("所有图块集验证通过")
	return true

# 新增：检查图层是否是碰撞图层
func _is_collision_layer(layer_data: Dictionary) -> bool:
	# 检查图层名称是否包含碰撞相关关键词
	var layer_name = layer_data.get("name", "").to_lower()
	var collision_keywords = ["collision", "collide", "block", "wall", "obstacle", "barrier"]
	
	for keyword in collision_keywords:
		if layer_name.contains(keyword):
			return true
	
	# 检查图层属性
	if layer_data.has("properties"):
		var properties = layer_data["properties"]
		for prop in properties:
			var prop_name = prop.get("name", "").to_lower()
			var prop_value = prop.get("value", false)
			
			if (prop_name == "collision" or prop_name == "collide") and prop_value == true:
				return true
	
	return false

# 检查图层是否遮盖层
func _is_cover_layer(layer_data: Dictionary) -> bool:
	var layer_name = layer_data.get("name", "").to_lower()
	var cover_keywords = ["coverlayer"]
	for keyword in cover_keywords:
		if layer_name.contains(keyword):
			return true
	return false

# 新增：将碰撞图层绘制到现有的TileMapLayer中
func _draw_collision_layer_to_static_tilemap(layer_data: Dictionary, atlas_coords = Vector2i(0, 1)):
	#print("绘制碰撞图层到现有TileMapLayer: " + layer_data["name"])
	
	# 使用已有的collision_tileMapLayer引用
	if not collision_tileMapLayer:
		push_error("找不到collision_tileMapLayer节点")
		return
	
	# 确保TileMapLayer有正确的TileSet
	if not collision_tileMapLayer.tile_set:
		collision_tileMapLayer.tile_set = tileset
	
	var layer_width = layer_data.get("width", 0)
	var layer_height = layer_data.get("height", 0)
	var tiles = layer_data.get("data", [])
	
	if tiles.size() == 0 or layer_width == 0 or layer_height == 0:
		#print("空碰撞图层: " + layer_data["name"])
		return
	
	# 确保宽度和高度是整数
	layer_width = int(layer_width)
	layer_height = int(layer_height)
	
	# 获取TileMapLayer的TileSet信息
	var layer_tileset = collision_tileMapLayer.tile_set
	if not layer_tileset:
		push_error("TileMapLayer没有TileSet")
		return
	
	# 获取TileSet中的第一个图块信息
	var first_source_id = -1
	#var first_atlas_coords = Vector2i(0, 0)
	
	if layer_tileset.get_source_count() > 0:
		var first_source = layer_tileset.get_source(0)
		if first_source:
			first_source_id = 0  # 第一个源的ID通常是0
			# 使用第一个图块的位置 (0, 1)
			#first_atlas_coords = Vector2i(0, 1)
			#print("使用TileSet第一个图块: 源ID=", first_source_id, " 坐标=", atlas_coords)
	else:
		push_error("TileSet没有可用的源")
		return
	
	# 填充碰撞图层瓦片
	#var collision_tiles_count = 0
	for index in range(tiles.size()):
		var tile_gid = int(tiles[index])  # 保持原始GID（Tiled从1计数）
		
		# 计算坐标位置
		var x = int(index) % layer_width
		var y = int(index) / layer_width
		
		# 跳过空瓦片
		if tile_gid <= 0:
			if atlas_coords == Vector2i(0, 1):
				nav_layer.set_cell(
					Vector2i(x, y),  # coords
					0,  # source_id (int类型)
					Vector2i(9, 3),  # atlas_coords (Vector2i类型)
					0,  # layer
				)
			continue
		
		# 在TileMapLayer上绘制第一个图块作为碰撞块
		# 注意：TileMapLayer的set_cell API可能不同，需要测试
		if collision_tileMapLayer.has_method("set_cell"):
			# 根据错误信息，第3个参数应该是Vector2i，第4个参数是int
			# set_cell(coords: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0)
			collision_tileMapLayer.set_cell(
				Vector2i(x, y),  # coords
				first_source_id,  # source_id (int类型)
				atlas_coords,  # atlas_coords (Vector2i类型)
				0,  # layer
			)
			#collision_tiles_count += 1
		else:
			print("警告：TileMapLayer没有set_cell方法")
			break
	
	#print("碰撞图层绘制完成: " + layer_data["name"])
	#print(" - 碰撞图块数量: ", collision_tiles_count)
	
	# 获取图块数量（根据节点类型使用不同的API）
	if collision_tileMapLayer.has_method("get_used_cells"):
		var _cells = collision_tileMapLayer.get_used_cells()
		#print(" - TileMapLayer总图块数量: ", cells.size())
	else:
		print(" - 无法获取图块数量")

# 新增：创建动态TileMap图层（用于非碰撞图层）
func _create_dynamic_tilemap_layer(layer_data: Dictionary):
	#print("创建动态TileMap图层: " + layer_data["name"])
	
	# 创建TileMap节点
	var tilemap = MAP_LAYER.instantiate()
	tilemap.name = layer_data["name"]
	tilemap.visible = layer_data.get("visible", true)
	#tilemap.z_index = current_layer_index  # 使用索引作为Z排序
	
	# 设置TileSet - 直接使用主TileSet
	tilemap.tile_set = tileset
	
	# 验证TileSet是否正确设置
	if tilemap.tile_set == null:
		print("错误：TileMap的TileSet为null")
		return
	elif tilemap.tile_set.get_source_count() == 0:
		print("错误：TileMap的TileSet没有源  ", current_layer_index, layers_to_load.size())
		if current_layer_index >= layers_to_load.size() - 1:
			force_reload_tilesets()
		return
	
	# 添加到地图容器
	add_child(tilemap)
	
	var layer_width = layer_data.get("width", 0)
	var layer_height = layer_data.get("height", 0)
	var tiles = layer_data.get("data", [])
	
	if tiles.size() == 0 or layer_width == 0 or layer_height == 0:
		#print("空图层: " + layer_data["name"])
		return
	
	# 确保宽度和高度是整数
	layer_width = int(layer_width)
	layer_height = int(layer_height)
	
	# 填充图层瓦片
	for index in range(tiles.size()):
		var tile_gid = int(tiles[index])  # 保持原始GID（Tiled从1计数）
		
		# 跳过空瓦片
		if tile_gid <= 0: continue
		
		# 计算坐标位置
		var x = int(index) % layer_width
		var y = int(index) / layer_width
		
		# 根据GID确定图块集和本地坐标
		var tileset_info = _get_tileset_info_for_gid(tile_gid)
		if tileset_info.is_empty():
			print("警告：无法找到GID ", tile_gid, " 对应的图块集")
			continue

		tilemap.set_cell(
			Vector2i(x, y),  # coords
			tileset_info.source_id,  # source_id
			tileset_info.atlas_coords,  # atlas_coords
			0,  # layer
		)
		
		if y == 0 or (y != 0 and (x == 0 or x >= layer_width - 1) or y >= layer_height - 1):
			collision_tileMapLayer.set_cell(
				Vector2i(x, y),  # coords
				0,  # source_id (int类型)
				Vector2i(0, 1),  # atlas_coords (Vector2i类型)
				0,  # layer
			)
	
	#print("动态图层创建完成: " + layer_data["name"])
	#print(" - 图块数量: ", tilemap.get_used_cells(0).size())

# 新增：根据GID获取图块集信息
func _get_tileset_info_for_gid(gid: int) -> Dictionary:
	# 找到对应的图块集
	var tileset_index = -1
	var local_tile_id = -1
	
	for i in range(tilesets_data.size()):
		var tileset_data = tilesets_data[i]
		var firstgid = tileset_data.get("firstgid", 1)
		var tilecount = tileset_data.get("tilecount", 0)
		
		# 如果tilecount为0，尝试从纹理尺寸计算
		if tilecount == 0 and tileset_textures.has(i):
			var _texture = tileset_textures[i]
			var image_size = _texture.get_size()
			tilecount = int(image_size.x / TILE_SIZE) * int(image_size.y / TILE_SIZE)
			print("从纹理计算图块数量: 图块集", i, " 纹理尺寸:", image_size, " 计算图块数:", tilecount)
		
		if gid >= firstgid and gid < firstgid + tilecount:
			tileset_index = i
			local_tile_id = gid - firstgid
			break
	
	if tileset_index == -1:
		print("警告：无法找到GID ", gid, " 对应的图块集索引")
		print("可用的图块集范围:")
		for i in range(tilesets_data.size()):
			var tileset_data = tilesets_data[i]
			var firstgid = tileset_data.get("firstgid", 1)
			var tilecount = tileset_data.get("tilecount", 0)
			print(" - 图块集 ", i, ": GID ", firstgid, " 到 ", firstgid + tilecount - 1)
		return {}
	
	# 检查图块集是否已加载
	if not tileset_textures.has(tileset_index):
		print("警告：图块集 ", tileset_index, " 尚未加载")
		print("已加载的图块集纹理: ", tileset_textures.keys())
		print("已加载的图块集源: ", tileset_sources.keys())
		return {}
	
	var texture = tileset_textures[tileset_index]
	var source_id = tileset_sources[tileset_index]
	
	# 计算图块在图集中的位置
	var tiles_per_row = int(texture.get_size().x / TILE_SIZE)
	var atlas_x = int(local_tile_id) % tiles_per_row
	var atlas_y = int(local_tile_id) / tiles_per_row
	
	# 验证坐标是否在有效范围内
	var max_tiles = int(texture.get_size().x / TILE_SIZE) * int(texture.get_size().y / TILE_SIZE)
	if local_tile_id >= max_tiles:
		print("警告：GID ", gid, " 的本地ID ", local_tile_id, " 超出图块范围 (0-", max_tiles-1, ")")
		return {}
	
	return {
		"source_id": source_id,
		"atlas_coords": Vector2i(atlas_x, atlas_y),
		"tileset_index": tileset_index,
		"local_tile_id": local_tile_id
	}

# 处理图块集 - 修改为支持多个图块集
func _process_tilesets(tilesets_data_array: Array):
	if tilesets_data_array.size() == 0:
		push_warning("地图不包含任何图块集")
		return
	
	# 保存图块集数据
	tilesets_data = tilesets_data_array
	total_tilesets = tilesets_data.size()
	tilesets_loaded_count = 0
	tileset_requests.clear()
	current_tileset_request_index = 0
	
	print("发现 ", total_tilesets, " 个图块集")
	
	# 处理每个图块集
	for i in range(total_tilesets):
		var tileset_data = tilesets_data[i]
		#print("处理图块集 ", i, ": ", tileset_data.get("name", "未命名"))
		#print(" - firstgid: ", tileset_data.get("firstgid", 1))
		#print(" - tilecount: ", tileset_data.get("tilecount", 0))
		
		# 检查图块集是否在服务器上
		var tileset_url = tileset_data.get("image", "")
		var tileset_name = tileset_data.get("name", "")
		
		# 只有在版本匹配时才使用缓存
		if current_cache_version == server_cache_version:
			# 首先检查是否有缓存的tileset文件
			var cached_tileset = load_cached_tileset(tileset_name)
			if cached_tileset != null:
				print("使用缓存的tileset: ", tileset_name)
				# 直接使用缓存的tileset
				_use_cached_tileset(cached_tileset, i)
				continue
		else:
			print("缓存版本不匹配，跳过缓存检查: ", tileset_name)
		
		if tileset_url.begins_with("http"):
			#print("添加远程图块集请求 ", i, ": " + tileset_url)
			tileset_requests.append({"index": i, "url": tileset_url, "name": tileset_name})
		else:
			# 处理本地文件路径（如果需要）
			var image_path = tileset_data["image"]
			#print("加载本地图块集 ", i, ": " + image_path)
			
			# 直接加载本地文件
			var texture = load(image_path)
			if texture:
				_create_tileset_from_texture(texture, i, tileset_name)
			else:
				push_error("无法加载本地图块集纹理: " + image_path)
	
	# 开始加载远程图块集
	if tileset_requests.size() > 0:
		_load_next_tileset_request()
	else:
		# 如果没有远程图块集，检查是否所有图块集都已加载
		if tilesets_loaded_count >= total_tilesets:
			#print("所有图块集加载完成！")
			# 如果图层队列已准备好，开始加载图层
			if layers_to_load.size() > 0 and current_layer_index >= 0:
				_load_next_layer()

# 新增：加载下一个图块集请求
func _load_next_tileset_request():
	if current_tileset_request_index >= tileset_requests.size():
		# 所有远程图块集请求已完成
		if tilesets_loaded_count >= total_tilesets:
			#print("所有图块集加载完成！")
			# 如果图层队列已准备好，开始加载图层
			if layers_to_load.size() > 0 and current_layer_index >= 0:
				_load_next_layer()
		return
	
	var request = tileset_requests[current_tileset_request_index]
	#print("开始加载远程图块集 ", request.index, ": " + request.url)
	#http_request.request(request.url)
	var image_res = await Request._http_request_image(request.url)
	if image_res == null:
		return
	var image_data = image_res.image_data
	var content_type = image_res.content_type
	var texture = Utils.texture_from_bytes(image_data)
	if texture == null:
		push_error("无法从字节数据创建纹理")
		return
	
	# 获取当前请求的图块集索引
	var tileset_index = tileset_requests[current_tileset_request_index].index
	var tileset_name = tileset_requests[current_tileset_request_index].name
	
	# 保存纹理引用
	tileset_textures[tileset_index] = texture
	
	# 创建图块集
	_create_tileset_from_texture(texture, tileset_index, tileset_name)
	
	# 可选：保存到缓存以备将来使用
	_save_to_cache_deferred(image_data, content_type, tileset_index, tileset_name)
	
	# 移动到下一个请求
	current_tileset_request_index += 1
	
	# 检查是否还有其他图块集需要加载
	_load_next_tileset_request()

# 核心图块集创建功能 - 修改为支持多个图块集
func _create_tileset_from_texture(texture: Texture2D, tileset_index: int, tileset_name: String = ""):
	if texture == null:
		push_error("无效的纹理资源")
		return
	
	#print("创建图块集 ", tileset_index, "，纹理尺寸: " + str(texture.get_size()))
	
	# 计算图块数量
	var image_size = texture.get_size()
	var tile_count_x = int(image_size.x / TILE_SIZE)
	var tile_count_y = int(image_size.y / TILE_SIZE)
	var _total_tiles = tile_count_x * tile_count_y
	tileset.resource_name = tileset_name
	
	# 创建图集源
	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# 添加所有图块
	for y in range(tile_count_y):
		for x in range(tile_count_x):
			# 创建图块使用正确的位置向量
			var tile_pos = Vector2i(x, y)
			source.create_tile(tile_pos)
	# 将源添加到TileSet
	var source_id = tileset.add_source(source)
	
	# 确保源被正确添加
	if source_id == -1:
		push_error("添加图块源失败")
		return
	
	# 保存源ID映射
	tileset_sources[tileset_index] = source_id
	
	# 保存纹理引用
	tileset_textures[tileset_index] = texture
	
	#print("图块集 ", tileset_index, " 创建完成，包含图块: " + str(total_tiles))
	#print(" - 源ID: ", source_id)
	
	# 如果提供了tileset_name，保存到缓存
	if not tileset_name.is_empty():
		# 创建一个独立的tileset用于缓存
		var cache_tileset = TileSet.new()
		cache_tileset.add_source(source)
		save_tileset_to_cache(cache_tileset, tileset_name)
	
	# 增加已加载计数
	tilesets_loaded_count += 1
	
	# 调试：打印TileSet信息
	#print("TileSet源数量: ", tileset.get_source_count())
	#print("已加载图块集: ", tilesets_loaded_count, "/", total_tilesets)
	
	# 如果所有图块集已加载，标记为完成
	if tilesets_loaded_count >= total_tilesets:
		tileset_loaded = true
		print("所有图块集加载完成！")
		
		# 如果图层队列已准备好，开始加载图层
		if layers_to_load.size() > 0 and current_layer_index >= 0:
			_load_next_layer()

# 后台保存到缓存（可选）- 修改为支持多个图块集
func _save_to_cache_deferred(data: PackedByteArray, content_type: String, _tileset_index: int, tileset_name: String):
	var extension = "png" if content_type == "image/png" else "jpg"
	var file_name = "tileset_" + tileset_name + "." + extension
	var file_path = CACHE_DIR.path_join(file_name)
	
	# 在后台线程保存
	var thread = Thread.new()
	thread.start(_save_thread_func.bind(file_path, data))
	
	#print("后台保存缓存文件: " + file_path)

# 线程保存函数
func _save_thread_func(file_path: String, data: PackedByteArray):
	# 确保目录存在
	if !DirAccess.dir_exists_absolute(CACHE_DIR):
		DirAccess.make_dir_absolute(CACHE_DIR)
	
	# 创建文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_buffer(data)
		file.close()
		#print("缓存文件保存成功: " + file_path)
	else:
		push_error("无法创建缓存文件: " + file_path)

# 加载缓存的tileset文件
func load_cached_tileset(tileset_name: String) -> TileSet:
	# 确保缓存目录已初始化
	if TILESET_CACHE_DIR.is_empty():
		return null
	
	var tileset_path = TILESET_CACHE_DIR.path_join(tileset_name + ".tres")
	
	if not FileAccess.file_exists(tileset_path):
		return null
	
	var cached_tileset = load(tileset_path)
	if cached_tileset is TileSet:
		#print("成功加载缓存的tileset: ", tileset_path)
		return cached_tileset
	else:
		#print("缓存的tileset文件格式错误: ", tileset_path)
		return null

# 使用缓存的tileset
func _use_cached_tileset(cached_tileset: TileSet, tileset_index: int):
	# 将缓存的tileset添加到主tileset中
	var source_count = cached_tileset.get_source_count()
	var texture_found = false
	
	for i in range(source_count):
		var source = cached_tileset.get_source(i)
		if source:
			var source_id = tileset.add_source(source)
			if source_id != -1:
				tileset_sources[tileset_index] = source_id
				#print("成功添加缓存的tileset源: ", tileset_index, " -> ", source_id)
				
				# 从源中获取纹理并保存到tileset_textures字典中
				if source is TileSetAtlasSource:
					var atlas_source = source as TileSetAtlasSource
					var texture = atlas_source.texture
					if texture:
						tileset_textures[tileset_index] = texture
						texture_found = true
						#print("成功设置缓存的tileset纹理: ", tileset_index)
	
	# 如果没有找到纹理，尝试从原始数据中获取
	if not texture_found:
		print("警告：缓存的tileset中没有找到纹理，尝试从原始数据获取")
		# 这里可以尝试从tilesets_data中获取纹理URL并重新加载
		if tileset_index < tilesets_data.size():
			var tileset_data = tilesets_data[tileset_index]
			var tileset_url = tileset_data.get("image", "")
			if tileset_url.begins_with("http"):
				# 将请求添加到队列中
				tileset_requests.append({
					"index": tileset_index, 
					"url": tileset_url, 
					"name": tileset_data.get("name", "")
				})
				# 如果当前没有在处理请求，开始处理
				if current_tileset_request_index >= tileset_requests.size():
					_load_next_tileset_request()
				return
	
	# 增加已加载计数
	tilesets_loaded_count += 1
	
	# 检查是否所有图块集都已加载
	if tilesets_loaded_count >= total_tilesets:
		tileset_loaded = true
		if layers_to_load.size() > 0 and current_layer_index >= 0:
			_load_next_layer()

# 保存tileset到缓存
func save_tileset_to_cache(tileset_to_save: TileSet, tileset_name: String) -> bool:
	# 确保缓存目录已初始化
	if TILESET_CACHE_DIR.is_empty():
		push_error("Tileset缓存目录路径未初始化")
		return false
	
	var tileset_path = TILESET_CACHE_DIR.path_join(tileset_name + ".tres")
	
	# 确保目录存在
	if not DirAccess.dir_exists_absolute(TILESET_CACHE_DIR):
		DirAccess.make_dir_absolute(TILESET_CACHE_DIR)
	
	# 保存tileset资源
	var error = ResourceSaver.save(tileset_to_save, tileset_path)
	if error == OK:
		return true
	else:
		push_error("保存tileset到缓存失败: " + str(error))
		return false

# 清理tileset缓存
func clear_tileset_cache():
	# 确保缓存目录已初始化
	if TILESET_CACHE_DIR.is_empty():
		push_error("Tileset缓存目录路径未初始化")
		return
	
	var dir = DirAccess.open(TILESET_CACHE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				#var file_path = TILESET_CACHE_DIR.path_join(file_name)
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("无法访问tileset缓存目录")

# 获取tileset缓存信息
func get_tileset_cache_info() -> Dictionary:
	var info = {
		"game_id": game_id,
		"cache_dir": TILESET_CACHE_DIR,
		"files": [],
		"total_size": 0
	}
	
	# 确保缓存目录已初始化
	if TILESET_CACHE_DIR.is_empty():
		return info
	
	var dir = DirAccess.open(TILESET_CACHE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var file_path = TILESET_CACHE_DIR.path_join(file_name)
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var file_size = file.get_length()
					info.files.append({
						"name": file_name,
						"size": file_size
					})
					info.total_size += file_size
					file.close()
			file_name = dir.get_next()
		dir.list_dir_end()
	
	return info

# 加载缓存版本
func load_cache_version():
	# 构建缓存路径
	var game_cache_dir = GAME_CACHE_ROOT.path_join(game_id)
	CACHE_VERSION_FILE = game_cache_dir.path_join("cache_version.json")
	print("CACHE_VERSION_FILE ===>", CACHE_VERSION_FILE)
	# 确保缓存目录已初始化
	if CACHE_VERSION_FILE.is_empty():
		return false
	
	if FileAccess.file_exists(CACHE_VERSION_FILE):
		var file = FileAccess.open(CACHE_VERSION_FILE, FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			if parse_result == OK:
				var data = json.get_data()
				current_cache_version = data.get("version", "")
				print("加载缓存版本: ", current_cache_version)
				return true
			file.close()
			return false
		else:
			print("无法读取缓存版本文件")
			return false
	else:
		print("缓存版本文件不存在，使用空版本")
		return false

# 保存缓存版本
func save_cache_version():
	# 确保缓存目录已初始化
	if CACHE_VERSION_FILE.is_empty():
		push_error("缓存版本文件路径未初始化")
		return
	
	# 确保目录存在
	var dir = DirAccess.open(CACHE_VERSION_FILE.get_base_dir())
	if not dir:
		DirAccess.make_dir_absolute(CACHE_VERSION_FILE.get_base_dir())
	
	# 创建版本数据
	var version_data = {
		"version": current_cache_version,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# 保存到文件
	var file = FileAccess.open(CACHE_VERSION_FILE, FileAccess.WRITE)
	if file:
		JSON.stringify(version_data)
		file.store_string(JSON.stringify(version_data))
		file.close()
		print("缓存版本已保存: ", current_cache_version)
	else:
		push_error("无法保存缓存版本文件")

# 清理所有缓存
func clear_all_cache():
	clear_tileset_cache()
	clear_map_cache()
	current_cache_version = ""
	save_cache_version()
	print("所有缓存已清理")

# 清理地图缓存
func clear_map_cache():
	# 确保缓存目录已初始化
	if CACHE_DIR.is_empty():
		push_error("地图缓存目录路径未初始化")
		return
	
	var dir = DirAccess.open(CACHE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				#var file_path = CACHE_DIR.path_join(file_name)
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("无法访问地图缓存目录")

# 获取缓存统计信息
func get_cache_stats() -> Dictionary:
	var stats = {
		"game_id": game_id,
		"local_version": current_cache_version,
		"server_version": server_cache_version,
		"version_match": current_cache_version == server_cache_version,
		"map_cache_files": 0,
		"map_cache_size": 0,
		"tileset_cache_files": 0,
		"tileset_cache_size": 0
	}
	
	# 统计地图缓存
	if not CACHE_DIR.is_empty():
		var dir = DirAccess.open(CACHE_DIR)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					stats.map_cache_files += 1
					var file_path = CACHE_DIR.path_join(file_name)
					var file = FileAccess.open(file_path, FileAccess.READ)
					if file:
						stats.map_cache_size += file.get_length()
						file.close()
				file_name = dir.get_next()
			dir.list_dir_end()
	
	# 统计tileset缓存
	if not TILESET_CACHE_DIR.is_empty():
		var dir = DirAccess.open(TILESET_CACHE_DIR)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					stats.tileset_cache_files += 1
					var file_path = TILESET_CACHE_DIR.path_join(file_name)
					var file = FileAccess.open(file_path, FileAccess.READ)
					if file:
						stats.tileset_cache_size += file.get_length()
						file.close()
				file_name = dir.get_next()
			dir.list_dir_end()
	
	return stats

# 检查缓存是否有效
func is_cache_valid() -> bool:
	return current_cache_version == server_cache_version

# 强制重新加载所有tileset
func force_reload_tilesets():
	print("强制重新加载所有tileset...")
	
	# 清理当前状态
	tileset_textures.clear()
	tileset_sources.clear()
	tilesets_loaded_count = 0
	tileset_requests.clear()
	current_tileset_request_index = 0
	current_layer_index = 0
	
	# 重新处理图块集
	if tilesets_data.size() > 0:
		_process_tilesets(tilesets_data)
	else:
		print("没有图块集数据可重新加载")

func load_game_data() -> void:
	# 服务端加载sqlite数据库数据
	if is_multiplayer_authority():
		var game_data = await GameDataService.export_game_data_for_game_id(game_id)
		process_game_data(game_data)
	# 客户端通过接口加载数据
	else:
		print("客户端加载游戏数据")
		remote_json_url = "http://" + GlobalData.server_ip + ":" + str(Config.HTTP_PORT) + "/api/game/export?game_id=" + game_id
		var game_catch_data = await GameCatch.load_game_json(game_id)
		if game_catch_data != null:
			process_game_data(game_catch_data)
			return
		load_remote_map()
	
	# remote_json_url = REMOTE_JSON_PATH + game_id
	# var game_catch_data = GameCatch.load_game_json(game_id)
	# if game_catch_data != null:
	# 	process_game_data(game_catch_data)
	# 	return
	# load_remote_map()
