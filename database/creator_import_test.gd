extends Node

# Creator JSON导入测试脚本
func _ready():
	if !is_multiplayer_authority():
		return
	
	# 等待1秒确保系统初始化完成
	await get_tree().create_timer(1.0).timeout
	
	print("=== Creator JSON 导入测试 ===")
	test_creator_import()

func test_creator_import():
	# 测试导入Creator格式的JSON数据
	var json_file_path = "res://GY3MCVANW_creator.json"
	
	print("开始导入Creator JSON: " + json_file_path)
	
	var success = JSONImporter.import_from_json_file(json_file_path)
	
	if success:
		print("✅ Creator JSON导入成功")
		check_imported_data()
	else:
		print("❌ Creator JSON导入失败")

func check_imported_data():
	print("\n--- 检查导入的数据 ---")
	
	# 检查世界数据
	var world_query = "SELECT COUNT(*) as count FROM worlds"
	var world_results = SQLiteManager.execute_query(world_query)
	if world_results.size() > 0:
		print("📊 世界数量: " + str(world_results[0].count))
	
	# 检查角色数据
	var character_query = "SELECT COUNT(*) as count FROM characters"
	var character_results = SQLiteManager.execute_query(character_query)
	if character_results.size() > 0:
		print("📊 角色数量: " + str(character_results[0].count))
	
	# 检查游戏数据
	var game_query = "SELECT COUNT(*) as count FROM games"
	var game_results = SQLiteManager.execute_query(game_query)
	if game_results.size() > 0:
		print("📊 游戏数量: " + str(game_results[0].count))
	
	# 检查章节数据
	var chapter_query = "SELECT COUNT(*) as count FROM chapters"
	var chapter_results = SQLiteManager.execute_query(chapter_query)
	if chapter_results.size() > 0:
		print("📊 章节数量: " + str(chapter_results[0].count))
	
	# 检查章节角色实例数据
	var instance_query = "SELECT COUNT(*) as count FROM chapter_character_instances"
	var instance_results = SQLiteManager.execute_query(instance_query)
	if instance_results.size() > 0:
		print("📊 章节角色实例数量: " + str(instance_results[0].count))
	
	# 查看具体的角色数据
	print("\n--- 角色详情 ---")
	var detailed_character_query = """
	SELECT c.character_id, c.name, c.world_id, c.type, c.pronouns, c.background
	FROM characters c
	LIMIT 3
	"""
	var detailed_results = SQLiteManager.execute_query(detailed_character_query)
	for character in detailed_results:
		print("🎭 角色: " + character.name + " (ID: " + character.character_id + ", 类型: " + character.type + ")")
		if character.background != "":
			print("   背景: " + character.background)
		if character.pronouns != "":
			print("   性别: " + character.pronouns)
	
	# 查看章节角色实例
	print("\n--- 章节角色实例 ---")
	var instance_detail_query = """
	SELECT cci.chapter_id, cci.character_id, cci.hp, cci.mp, c.name
	FROM chapter_character_instances cci
	JOIN characters c ON cci.character_id = c.character_id
	LIMIT 3
	"""
	var instance_detail_results = SQLiteManager.execute_query(instance_detail_query)
	for instance in instance_detail_results:
		print("🎮 实例: " + instance.name + " 在章节 " + instance.chapter_id + " (血量: " + str(instance.hp) + ")")

# 测试查询跨章节的角色复用
func test_character_reuse():
	print("\n--- 测试角色跨章节复用 ---")
	
	# 查找在多个章节中使用的角色
	var reuse_query = """
	SELECT c.character_id, c.name, COUNT(cci.chapter_id) as chapter_count
	FROM characters c
	LEFT JOIN chapter_character_instances cci ON c.character_id = cci.character_id
	GROUP BY c.character_id, c.name
	HAVING chapter_count > 0
	ORDER BY chapter_count DESC
	"""
	
	var reuse_results = SQLiteManager.execute_query(reuse_query)
	
	if reuse_results.size() > 0:
		print("🔄 角色复用情况:")
		for result in reuse_results:
			print("  - " + result.name + " (ID: " + result.character_id + ") 用于 " + str(result.chapter_count) + " 个章节")
	else:
		print("❌ 没有找到角色复用数据")

# 测试新数据架构的优势
func demonstrate_new_architecture():
	print("\n--- 演示新架构优势 ---")
	
	# 1. 世界级别的角色管理
	print("1. 世界级别角色管理:")
	var world_characters_query = """
	SELECT w.name as world_name, c.character_id, c.name as character_name, c.type
	FROM worlds w
	JOIN characters c ON w.world_id = c.world_id
	"""
	var world_char_results = SQLiteManager.execute_query(world_characters_query)
	for result in world_char_results:
		print("   世界「" + result.world_name + "」包含角色: " + result.character_name + " (" + result.type + ")")
	
	# 2. 章节级别的角色实例
	print("\n2. 章节级别角色实例:")
	var chapter_instances_query = """
	SELECT ch.name as chapter_name, c.name as character_name, cci.hp, cci.mp
	FROM chapters ch
	JOIN chapter_character_instances cci ON ch.chapter_id = cci.chapter_id
	JOIN characters c ON cci.character_id = c.character_id
	"""
	var chapter_inst_results = SQLiteManager.execute_query(chapter_instances_query)
	for result in chapter_inst_results:
		print("   章节「" + result.chapter_name + "」中的 " + result.character_name + ": HP=" + str(result.hp) + ", MP=" + str(result.mp))

# 手动调用的测试方法
func run_full_test():
	test_creator_import()
	await get_tree().create_timer(1.0).timeout
	test_character_reuse()
	await get_tree().create_timer(0.5).timeout
	demonstrate_new_architecture() 