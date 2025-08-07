extends Node

# 正确的 godot-sqlite 使用示例
var db : SQLite

func _ready():
	if !is_multiplayer_authority():
		return
	
	# 等待1秒确保系统初始化完成
	await get_tree().create_timer(1.0).timeout
	
	print("开始数据库使用示例...")
	test_sqlite_basic_usage()

func test_sqlite_basic_usage():
	print("=== Godot-SQLite 基础使用示例 ===")
	
	# 1. 创建数据库实例
	db = SQLite.new()
	
	# 2. 设置数据库路径和选项
	db.path = "user://test_example.db"
	db.verbosity_level = SQLite.NORMAL
	db.foreign_keys = true
	
	# 3. 打开数据库
	if not db.open_db():
		push_error("无法打开数据库: " + db.error_message)
		return
	
	print("✅ 数据库打开成功")
	
	# 4. 创建测试表
	create_test_tables()
	
	# 5. 插入测试数据
	insert_test_data()
	
	# 6. 查询数据
	query_test_data()
	
	# 7. 使用参数化查询
	test_parameterized_queries()
	
	# 8. 关闭数据库
	if db.close_db():
		print("✅ 数据库关闭成功")
	
	print("=== 示例完成 ===")

func create_test_tables():
	print("\n--- 创建测试表 ---")
	
	# 使用 create_table 方法创建表
	var table_dict = {}
	
	# 用户表
	table_dict["id"] = {
		"data_type": "int",
		"primary_key": true,
		"auto_increment": true
	}
	table_dict["name"] = {
		"data_type": "text",
		"not_null": true
	}
	table_dict["email"] = {
		"data_type": "text",
		"unique": true
	}
	table_dict["age"] = {
		"data_type": "int",
		"default": 0
	}
	table_dict["created_at"] = {
		"data_type": "text",
		"default": "'CURRENT_TIMESTAMP'"
	}
	
	if db.create_table("users", table_dict):
		print("✅ 用户表创建成功")
	else:
		print("❌ 用户表创建失败: " + db.error_message)
	
	# 使用原始SQL创建游戏表
	var create_games_sql = """
	CREATE TABLE IF NOT EXISTS games (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		title TEXT NOT NULL,
		genre TEXT,
		user_id INTEGER,
		score REAL DEFAULT 0.0,
		FOREIGN KEY (user_id) REFERENCES users(id)
	);
	"""
	
	if db.query(create_games_sql):
		print("✅ 游戏表创建成功")
	else:
		print("❌ 游戏表创建失败: " + db.error_message)

func insert_test_data():
	print("\n--- 插入测试数据 ---")
	
	# 使用 insert_row 方法
	var user_data = {
		"name": "张三",
		"email": "zhangsan@example.com",
		"age": 25
	}
	
	if db.insert_row("users", user_data):
		print("✅ 用户数据插入成功，ID: " + str(db.last_insert_rowid))
	else:
		print("❌ 用户数据插入失败: " + db.error_message)
	
	# 批量插入用户
	var users_array = [
		{"name": "李四", "email": "lisi@example.com", "age": 30},
		{"name": "王五", "email": "wangwu@example.com", "age": 28},
		{"name": "赵六", "email": "zhaoliu@example.com", "age": 35}
	]
	
	if db.insert_rows("users", users_array):
		print("✅ 批量用户数据插入成功")
	else:
		print("❌ 批量用户数据插入失败: " + db.error_message)
	
	# 使用原始SQL插入游戏数据
	var insert_games_sql = """
	INSERT INTO games (title, genre, user_id, score) VALUES 
	('超级马里奥', 'Platform', 1, 9.5),
	('塞尔达传说', 'Adventure', 1, 9.8),
	('俄罗斯方块', 'Puzzle', 2, 8.5),
	('魂斗罗', 'Action', 3, 8.8);
	"""
	
	if db.query(insert_games_sql):
		print("✅ 游戏数据插入成功")
	else:
		print("❌ 游戏数据插入失败: " + db.error_message)

func query_test_data():
	print("\n--- 查询测试数据 ---")
	
	# 查询所有用户
	var users = db.select_rows("users", "", ["*"])
	print("📊 用户总数: " + str(users.size()))
	for user in users:
		print("  - " + user.name + " (ID: " + str(user.id) + ", 邮箱: " + user.email + ")")
	
	# 条件查询
	var young_users = db.select_rows("users", "age < 30", ["name", "age"])
	print("📊 30岁以下用户:")
	for user in young_users:
		print("  - " + user.name + " (年龄: " + str(user.age) + ")")
	
	# 使用原始SQL进行复杂查询
	var join_query = """
	SELECT u.name, g.title, g.score 
	FROM users u 
	JOIN games g ON u.id = g.user_id 
	WHERE g.score > 9.0
	ORDER BY g.score DESC;
	"""
	
	if db.query(join_query):
		print("📊 高分游戏及其玩家:")
		for row in db.query_result:
			print("  - " + row.name + " 的 " + row.title + " (评分: " + str(row.score) + ")")
	else:
		print("❌ 联表查询失败: " + db.error_message)

func test_parameterized_queries():
	print("\n--- 参数化查询测试 ---")
	
	# 安全的参数化查询
	var search_age = 30
	var search_query = "SELECT * FROM users WHERE age >= ?"
	var params = [search_age]
	
	if db.query_with_bindings(search_query, params):
		print("📊 " + str(search_age) + "岁及以上用户:")
		for user in db.query_result:
			print("  - " + user.name + " (年龄: " + str(user.age) + ")")
	else:
		print("❌ 参数化查询失败: " + db.error_message)
	
	# 更新数据
	var update_query = "UPDATE users SET age = ? WHERE name = ?"
	var update_params = [26, "张三"]
	
	if db.query_with_bindings(update_query, update_params):
		print("✅ 用户年龄更新成功")
	else:
		print("❌ 用户年龄更新失败: " + db.error_message)
	
	# 验证更新
	var verify_query = "SELECT name, age FROM users WHERE name = ?"
	var verify_params = ["张三"]
	
	if db.query_with_bindings(verify_query, verify_params):
		if db.query_result.size() > 0:
			var user = db.query_result[0]
			print("✅ 验证更新: " + user.name + " 的年龄现在是 " + str(user.age))
	else:
		print("❌ 验证查询失败: " + db.error_message)

# 演示事务处理
func test_transaction():
	print("\n--- 事务处理测试 ---")
	
	# 开始事务
	if not db.query("BEGIN TRANSACTION;"):
		print("❌ 开始事务失败: " + db.error_message)
		return
	
	# 执行多个操作
	var success = true
	
	# 插入新用户
	var new_user = {"name": "测试用户", "email": "test@example.com", "age": 20}
	if not db.insert_row("users", new_user):
		success = false
		print("❌ 插入用户失败: " + db.error_message)
	
	# 插入相关游戏
	var user_id = db.last_insert_rowid
	var insert_game_query = "INSERT INTO games (title, genre, user_id, score) VALUES (?, ?, ?, ?)"
	var game_params = ["测试游戏", "Test", user_id, 7.5]
	
	if not db.query_with_bindings(insert_game_query, game_params):
		success = false
		print("❌ 插入游戏失败: " + db.error_message)
	
	# 提交或回滚事务
	if success:
		if db.query("COMMIT;"):
			print("✅ 事务提交成功")
		else:
			print("❌ 事务提交失败: " + db.error_message)
	else:
		if db.query("ROLLBACK;"):
			print("⚠️ 事务已回滚")
		else:
			print("❌ 事务回滚失败: " + db.error_message)

# 导出和导入数据
func test_export_import():
	print("\n--- 数据导出导入测试 ---")
	
	# 导出到JSON
	var export_path = "user://database_backup.json"
	if db.export_to_json(export_path):
		print("✅ 数据库导出成功: " + export_path)
	else:
		print("❌ 数据库导出失败: " + db.error_message)
	
	# 检查文件是否存在
	if FileAccess.file_exists(export_path):
		print("✅ 导出文件确认存在")
		
		# 可以重新导入（注意：这会清空现有数据）
		# db.import_from_json(export_path)
	else:
		print("❌ 导出文件不存在")

# 手动调用的清理函数
func cleanup_test_database():
	if db:
		db.query("DROP TABLE IF EXISTS games;")
		db.query("DROP TABLE IF EXISTS users;")
		print("✅ 测试表已清理")
		db.close_db() 
