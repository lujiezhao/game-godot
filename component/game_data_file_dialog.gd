extends FileDialog

@onready var input_game_id: LineEdit = $"../Input_game_id"

func _ready() -> void:
	file_selected.connect(game_data_selected)

## 导入游戏json数据（支持多种格式）
func game_data_selected(path: String):
	print("📁 选择的文件: %s" % path)
	
	# 首先检测文件格式
	var format_info = _detect_file_format(path)
	if format_info.is_empty():
		print("❌ 无法读取或解析文件")
		return
	
	print("🔍 检测到格式: %s" % format_info.type)
	print("📋 文件信息: %s" % format_info.description)
	
	# 导入数据
	var success = JSONImporter.import_from_json_file(path)
	
	if success:
		print("✅ %s 导入成功" % format_info.type)
		_show_import_success(format_info)
	else:
		print("❌ %s 导入失败" % format_info.type)
		_show_import_error(format_info)

# 检测文件格式
func _detect_file_format(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	var data = json.data
	var format_type = JSONImporter.detect_data_format(data)
	
	var format_info = {
		"type": format_type,
		"file_path": file_path,
		"file_size": FileAccess.get_file_as_bytes(file_path).size()
	}
	
	# 根据格式添加描述信息
	match format_type:
		"EXPORT_FORMAT":
			format_info.description = "导出格式 - 包含完整的游戏数据结构"
			if data.has("game_info"):
				var game_info = data.game_info
				format_info.game_name = game_info.get("name", "未知游戏")
				format_info.game_id = game_info.get("game_id", "")
				format_info.chapters_count = game_info.get("chapters", []).size()
				
				# 统计角色数量（不包括玩家）
				var total_characters = 0
				for chapter in game_info.get("chapters", []):
					total_characters += chapter.get("characters", []).size()
				format_info.total_characters = total_characters
		
		"CREATOR_FORMAT":
			format_info.description = "Creator格式 - 包含世界和游戏层次结构"
			format_info.world_name = data.get("name", "未知世界")
			format_info.world_id = data.get("world_id", "")
			format_info.games_count = data.get("games", []).size()
		
		"LEGACY_FORMAT":
			format_info.description = "Legacy格式 - 旧版游戏数据格式"
			if data.has("game_info"):
				format_info.game_name = data.game_info.get("name", "未知游戏")
		
		_:
			format_info.description = "未知格式 - 无法识别的数据结构"
	
	return format_info

# 显示导入成功信息
func _show_import_success(format_info: Dictionary):
	var message = "🎉 导入成功！\n"
	message += "格式: %s\n" % format_info.type
	message += "描述: %s\n" % format_info.description
	
	if format_info.has("game_name"):
		message += "游戏: %s\n" % format_info.game_name
	if format_info.has("world_name"):
		message += "世界: %s\n" % format_info.world_name
	if format_info.has("chapters_count"):
		message += "章节数: %d\n" % format_info.chapters_count
	if format_info.has("total_characters"):
		message += "角色数: %d\n" % format_info.total_characters
	if format_info.has("games_count"):
		message += "游戏数: %d\n" % format_info.games_count
	
	message += "文件大小: %.1f KB" % (format_info.file_size / 1024.0)
	
	print(message)
	
	# 如果有game_id输入框，更新它
	if input_game_id != null and format_info.has("game_id"):
		input_game_id.text = format_info.game_id

# 显示导入错误信息
func _show_import_error(format_info: Dictionary):
	var message = "💥 导入失败！\n"
	message += "格式: %s\n" % format_info.type
	message += "请检查数据完整性或联系开发者。"
	
	print(message)
