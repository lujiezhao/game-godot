extends Node

func save_game_json(dataStr: String, gameId: String):
	DirAccess.make_dir_absolute(Config.GAME_CACHE_ROOT)
	
	var game_cache_dir = Config.GAME_CACHE_ROOT.path_join(gameId)
	DirAccess.make_dir_absolute(game_cache_dir)
	
	var file_path = game_cache_dir.path_join("game_data.json")
	var dir = DirAccess.open(file_path.get_base_dir())
	
	if not dir:
		print("make_dir_absolute")
		DirAccess.make_dir_absolute(file_path.get_base_dir())
	
	print(file_path)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	print(file)
	if file:
		print("try to save json")
		var _json = JSON.new()
		file.store_string(dataStr)
		file.close()
		print("游戏： %s 已保存" % gameId)
		return true
	return false

# 加载缓存版本
func load_game_json(gameId: String):
	var game_cache_dir = Config.GAME_CACHE_ROOT.path_join(gameId)
	var dir = DirAccess.open(game_cache_dir)
	if !dir:
		DirAccess.make_dir_absolute(game_cache_dir)
		return null
	
	var file_path = game_cache_dir.path_join("game_data.json")
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			if parse_result == OK:
				var data = json.get_data()
				return data
			file.close()
			return null
		else:
			print("无法读取缓存版本文件")
			return null
	else:
		print("缓存版本文件不存在，使用空版本")
		return null

func load_user_info():
	var file := FileAccess.open_encrypted_with_pass("user://user_info.dat", FileAccess.READ_WRITE, Config.TOKEN_KEY)
	if file != null:
		var user_info = file.get_var()
		file.close()
		return user_info
	return null

func save_user_info(user_info: Variant) -> void:
	var file = FileAccess.open_encrypted_with_pass("user://user_info.dat", FileAccess.WRITE, Config.TOKEN_KEY)
	if file != null:
		file.store_var(user_info)
		file.close()
	else:
		push_error("cannot write to user://user_info.dat")

func clear_user_info():
	DirAccess.remove_absolute("user://user_info.dat")
