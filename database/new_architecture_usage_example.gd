extends Node

# 新角色架构使用示例
func _ready():
	await get_tree().create_timer(2.0).timeout
	print("=== 新角色架构使用示例 ===")
	demonstrate_usage()

func demonstrate_usage():
	print("\n📚 这个示例展示了新角色架构的使用方法:")
	print("1. 角色现在属于世界(World)级别")
	print("2. 章节可以选择世界中的任何角色")
	print("3. 每个章节中的角色有独立的运行时状态")
	print("\n" + "=".repeat(50))
	
	example_1_create_world_characters()
	await get_tree().create_timer(1.0).timeout
	example_2_add_characters_to_chapters()
	await get_tree().create_timer(1.0).timeout
	example_3_query_combined_data()
	await get_tree().create_timer(1.0).timeout
	example_4_character_reuse_benefits()

# 示例1: 在世界级别创建角色
func example_1_create_world_characters():
	print("\n🌍 示例1: 在世界级别创建角色")
	print("```gdscript")
	print("# 在「魔法世界」中创建一个骑士角色")
	print("var character = CharacterModel.new({")
	print("    \"character_id\": \"KNIGHT_001\",")
	print("    \"world_id\": \"MAGIC_WORLD\",")
	print("    \"name\": \"亚瑟骑士\",")
	print("    \"type\": \"npc\",")
	print("    \"background\": \"来自卡美洛的圆桌骑士\",")
	print("    \"pronouns\": \"male\",")
	print("    \"traits\": [\"勇敢\", \"正义\", \"忠诚\"]")
	print("})")
	print("")
	print("# 保存角色到世界（不绑定到特定章节）")
	print("CharacterRepository.create(character)")
	print("```")
	print("✅ 角色现在属于整个世界，可以在任何章节中使用")

# 示例2: 在不同章节中使用同一角色
func example_2_add_characters_to_chapters():
	print("\n🎮 示例2: 在不同章节中使用同一角色")
	print("```gdscript")
	print("# 在「森林章节」中使用骑士")
	print("var forest_instance = ChapterCharacterInstanceModel.new({")
	print("    \"chapter_id\": \"FOREST_CHAPTER\",")
	print("    \"character_id\": \"KNIGHT_001\",")
	print("    \"hp\": 100,")
	print("    \"spawn_x\": 100.0,")
	print("    \"spawn_y\": 200.0,")
	print("    \"is_patrol\": true")
	print("})")
	print("")
	print("# 在「城堡章节」中也使用同一骑士，但状态不同")
	print("var castle_instance = ChapterCharacterInstanceModel.new({")
	print("    \"chapter_id\": \"CASTLE_CHAPTER\",")
	print("    \"character_id\": \"KNIGHT_001\",  # 同一个角色")
	print("    \"hp\": 80,  # 在城堡章节中受过伤")
	print("    \"spawn_x\": 300.0,  # 不同的出生位置")
	print("    \"spawn_y\": 400.0,")
	print("    \"is_patrol\": false  # 不同的行为")
	print("})")
	print("```")
	print("✅ 同一角色在不同章节中有独立的状态")

# 示例3: 查询组合数据
func example_3_query_combined_data():
	print("\n🔍 示例3: 查询角色的完整信息")
	print("```gdscript")
	print("# 获取角色的基础配置")
	print("var character = CharacterRepository.get_by_character_id(\"KNIGHT_001\")")
	print("")
	print("# 获取角色在特定章节的实例状态")
	print("var instance = ChapterCharacterInstanceRepository.get_by_chapter_and_character(")
	print("    \"FOREST_CHAPTER\", \"KNIGHT_001\"")
	print(")")
	print("")
	print("# 组合使用")
	print("print(\"角色名称: \", character.name)")
	print("print(\"角色背景: \", character.background)")
	print("print(\"当前血量: \", instance.hp)")
	print("print(\"当前位置: \", instance.get_current_position())")
	print("")
	print("# 高级查询：获取角色在所有章节中的实例")
	print("var all_instances = SQLiteManager.execute_query(\"\"\"")
	print("    SELECT cci.chapter_id, cci.hp, ch.name as chapter_name")
	print("    FROM chapter_character_instances cci")
	print("    JOIN chapters ch ON cci.chapter_id = ch.chapter_id")
	print("    WHERE cci.character_id = ?")
	print("\"\"\", [\"KNIGHT_001\"])")
	print("```")
	print("✅ 可以灵活查询角色的基础信息和章节状态")

# 示例4: 角色复用的优势
func example_4_character_reuse_benefits():
	print("\n🔄 示例4: 角色复用的优势")
	print("```gdscript")
	print("# 场景：创建一个剧情连续的多章节游戏")
	print("")
	print("# 1. 主角在整个故事中保持一致的人设")
	print("var hero = CharacterModel.new({")
	print("    \"character_id\": \"HERO_001\",")
	print("    \"world_id\": \"STORY_WORLD\",")
	print("    \"name\": \"勇者艾伦\",")
	print("    \"background\": \"被选中拯救世界的年轻人\",")
	print("    \"traits\": [\"勇敢\", \"善良\", \"坚持\"]")
	print("})")
	print("")
	print("# 2. 在第一章：新手村")
	print("var chapter1_hero = ChapterCharacterInstanceModel.new({")
	print("    \"chapter_id\": \"NEWBIE_VILLAGE\",")
	print("    \"character_id\": \"HERO_001\",")
	print("    \"hp\": 50,  # 初始状态较弱")
	print("    \"level\": 1")
	print("})")
	print("")
	print("# 3. 在第五章：最终决战")
	print("var chapter5_hero = ChapterCharacterInstanceModel.new({")
	print("    \"chapter_id\": \"FINAL_BATTLE\",")
	print("    \"character_id\": \"HERO_001\",  # 同一个角色")
	print("    \"hp\": 300,  # 经过冒险变强了")
	print("    \"level\": 50")
	print("})")
	print("```")
	print("")
	print("📈 优势总结:")
	print("  ✅ 一致的角色人设：背景、性格、AI配置在所有章节中保持一致")
	print("  ✅ 独立的状态管理：不同章节可以有不同的血量、位置、装备")
	print("  ✅ 减少数据冗余：角色基础配置只存储一次")
	print("  ✅ 易于管理：修改角色背景设定会影响所有章节")
	print("  ✅ 灵活的配置覆盖：可以在特定章节中覆盖某些行为")

# 展示实际的数据库查询
func show_real_data_if_available():
	print("\n📊 当前数据库中的实际数据:")
	
	# 检查是否有导入的数据
	var character_count_query = "SELECT COUNT(*) as count FROM characters"
	var results = SQLiteManager.execute_query(character_count_query)
	
	if results.size() > 0 and results[0].count > 0:
		print("角色总数: " + str(results[0].count))
		
		# 显示一些真实的角色数据
		var sample_query = """
		SELECT c.name, c.character_id, c.world_id, 
		       COUNT(cci.chapter_id) as chapter_usage_count
		FROM characters c
		LEFT JOIN chapter_character_instances cci ON c.character_id = cci.character_id
		GROUP BY c.character_id, c.name, c.world_id
		LIMIT 3
		"""
		var sample_results = SQLiteManager.execute_query(sample_query)
		
		for character in sample_results:
			print("  - " + character.name + " (ID: " + character.character_id + 
			      ") 用于 " + str(character.chapter_usage_count) + " 个章节")
	else:
		print("💡 提示：运行 creator_import_test.gd 来导入示例数据")

# 完整的演示流程
func run_complete_demo():
	demonstrate_usage()
	await get_tree().create_timer(2.0).timeout
	show_real_data_if_available() 

# ================================
# 多格式导入测试示例
# ================================

# 测试多格式数据导入
static func test_multi_format_import():
	print("\n=== 多格式导入测试 ===")
	
	# 测试文件路径
	var test_files = [
		"res://GY3MCVANW.json",           # 导出格式
		"res://GY3MCVANW_creator.json",  # Creator格式
		"res://GY3MCVANW_full.json"      # Full格式（如果存在）
	]
	
	for file_path in test_files:
		if FileAccess.file_exists(file_path):
			print("\n📁 测试文件: %s" % file_path)
			var success = JSONImporter.import_from_json_file(file_path)
			
			if success:
				print("✅ 导入成功: %s" % file_path)
			else:
				print("❌ 导入失败: %s" % file_path)
		else:
			print("⚠️ 文件不存在: %s" % file_path)
	
	print("\n=== 多格式导入测试完成 ===")

# 测试格式检测功能
static func test_format_detection():
	print("\n=== 格式检测测试 ===")
	
	# 模拟不同格式的数据
	var export_format_sample = {
		"game_info": {
			"name": "测试游戏",
			"game_id": "TEST_GAME",
			"chapters": []
		}
	}
	
	var creator_format_sample = {
		"world_id": "TEST_WORLD",
		"name": "测试世界",
		"games": [
			{
				"name": "测试游戏",
				"game_id": "TEST_GAME"
			}
		]
	}
	
	var legacy_format_sample = {
		"world_info": {
			"name": "测试世界"
		},
		"game_info": {
			"name": "测试游戏"
		}
	}
	
	# 测试格式检测
	var tests = [
		{"data": export_format_sample, "expected": "EXPORT_FORMAT"},
		{"data": creator_format_sample, "expected": "CREATOR_FORMAT"},
		{"data": legacy_format_sample, "expected": "LEGACY_FORMAT"}
	]
	
	for test in tests:
		var detected = JSONImporter.detect_data_format(test.data)
		var success = (detected == test.expected)
		
		print("%s 检测结果: %s (期望: %s)" % [
			"✅" if success else "❌",
			detected,
			test.expected
		])
	
	print("\n=== 格式检测测试完成 ===") 