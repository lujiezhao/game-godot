class_name MapLoader
extends RefCounted

const MAPS_DIR = "user://maps/"

# 加载地图数据
static func load_map(map_id: String) -> Dictionary:
	var file_path = get_map_file_path(map_id)
	
	if not FileAccess.file_exists(file_path):
		push_error("地图文件不存在: " + file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("无法打开地图文件: " + file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("地图JSON解析失败: " + file_path)
		return {}
	
	return json.data

# 保存地图数据
static func save_map(map_id: String, map_data: Dictionary) -> bool:
	var file_path = get_map_file_path(map_id)
	
	# 确保目录存在
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("maps"):
		dir.make_dir("maps")
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("无法创建地图文件: " + file_path)
		return false
	
	var json_string = JSON.stringify(map_data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("地图保存成功: " + file_path)
	return true

# 获取地图文件路径
static func get_map_file_path(map_id: String) -> String:
	return MAPS_DIR + "map_" + map_id + ".json"

# 检查地图文件是否存在
static func map_file_exists(map_id: String) -> bool:
	return FileAccess.file_exists(get_map_file_path(map_id))

# 删除地图文件
static func delete_map_file(map_id: String) -> bool:
	var file_path = get_map_file_path(map_id)
	
	if not FileAccess.file_exists(file_path):
		return true  # 文件不存在，视为删除成功
	
	var dir = DirAccess.open("user://")
	var result = dir.remove(file_path)
	
	if result == OK:
		print("地图文件删除成功: " + file_path)
		return true
	else:
		push_error("地图文件删除失败: " + file_path)
		return false

# 获取所有地图文件列表
static func get_all_map_files() -> Array:
	var maps = []
	var dir = DirAccess.open(MAPS_DIR)
	
	if dir == null:
		return maps
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json") and file_name.begins_with("map_"):
			var map_id = file_name.substr(4, file_name.length() - 9)  # 移除 "map_" 前缀和 ".json" 后缀
			maps.append(map_id)
		file_name = dir.get_next()
	
	return maps

# 复制地图文件
static func copy_map(source_map_id: String, target_map_id: String) -> bool:
	var source_path = get_map_file_path(source_map_id)
	var target_path = get_map_file_path(target_map_id)
	
	if not FileAccess.file_exists(source_path):
		push_error("源地图文件不存在: " + source_path)
		return false
	
	var source_file = FileAccess.open(source_path, FileAccess.READ)
	if source_file == null:
		push_error("无法读取源地图文件: " + source_path)
		return false
	
	var content = source_file.get_as_text()
	source_file.close()
	
	var target_file = FileAccess.open(target_path, FileAccess.WRITE)
	if target_file == null:
		push_error("无法创建目标地图文件: " + target_path)
		return false
	
	target_file.store_string(content)
	target_file.close()
	
	print("地图复制成功: " + source_path + " -> " + target_path)
	return true 