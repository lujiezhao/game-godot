extends Node

# 测试数据库系统
func _ready():
	if !is_multiplayer_authority():
		return
	# 等待1秒确保系统初始化完成
	await get_tree().create_timer(1.0).timeout
	
	print("开始数据库测试...")
	test_database_system()

func test_database_system():
	print("=== 数据库系统测试开始 ===")
	
	# 1. 初始化数据库
	var db_manager = SQLiteManager.get_instance()
	if db_manager == null:
		print("❌ 数据库初始化失败")
		return
	
	print("✅ 数据库初始化成功")
	
	# 2. 测试从JSON文件导入数据
	var json_file_path = "/Users/lujiezhao/rpggame-godot/GY3MCVANW_full.json"
	if FileAccess.file_exists(json_file_path):
		print("开始导入JSON数据...")
		
		var success = JSONImporter.import_from_json_file(json_file_path)
		if success:
			print("✅ JSON数据导入成功")
		else:
			print("❌ JSON数据导入失败")
			return
	else:
		print("⚠️ JSON文件不存在，跳过导入测试")
	
	# 3. 测试查询功能
	test_queries()
	
	print("=== 数据库系统测试完成 ===")

func test_queries():
	print("\n--- 查询测试开始 ---")
	
	# 查询所有游戏
	var games_query = "SELECT COUNT(*) as count FROM games"
	var results = SQLiteManager.execute_query(games_query)
	if results.size() > 0:
		print("✅ 游戏数量: " + str(results[0].count))
	
	# 查询所有角色
	var characters_query = "SELECT COUNT(*) as count FROM characters"
	results = SQLiteManager.execute_query(characters_query)
	if results.size() > 0:
		print("✅ 角色数量: " + str(results[0].count))
	
	# 查询所有建筑
	var buildings_query = "SELECT COUNT(*) as count FROM buildings"
	results = SQLiteManager.execute_query(buildings_query)
	if results.size() > 0:
		print("✅ 建筑数量: " + str(results[0].count))
	
	# 查询游戏详情
	var game_details_query = "SELECT game_id, name, category FROM games LIMIT 1"
	results = SQLiteManager.execute_query(game_details_query)
	if results.size() > 0:
		var game = results[0]
		print("✅ 游戏示例: " + game.name + " (ID: " + game.game_id + ", 类型: " + game.category + ")")
	
	print("--- 查询测试完成 ---\n")

# 手动调用的测试函数
func test_create_sample_data():
	print("创建示例数据...")
	
	# 创建示例世界
	var world_data = {
		"world_id": "TEST_WORLD_001",
		"name": "测试世界",
		"user_id": "test_user_001",
		"world_view": "这是一个测试世界",
		"status": "normal",
		"version": 1
	}
	
	var world = WorldModel.new(world_data)
	if WorldRepository.create(world):
		print("✅ 示例世界创建成功")
	else:
		print("❌ 示例世界创建失败")
	
	# 创建示例游戏
	var game_data = {
		"game_id": "TEST_GAME_001",
		"name": "测试游戏",
		"category": "adventure",
		"user_id": "test_user_001",
		"genre": "published"
	}
	
	var game = GameModel.new(game_data)
	if GameRepository.create(game):
		print("✅ 示例游戏创建成功")
	else:
		print("❌ 示例游戏创建失败")

# 数据库状态检查
func check_database_status():
	print("\n=== 数据库状态检查 ===")
	
	var tables = [
		"worlds", "games", "chapters", "characters", "buildings", 
		"props", "sessions", "authors", "game_interactions"
	]
	
	for table in tables:
		var query = "SELECT COUNT(*) as count FROM " + table
		var results = SQLiteManager.execute_query(query)
		if results.size() > 0:
			print("📊 " + table + ": " + str(results[0].count) + " 条记录")
		else:
			print("❌ " + table + ": 查询失败")
	
	print("===================\n") 
