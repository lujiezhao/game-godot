class_name SQLiteManager
extends RefCounted

static var instance: SQLiteManager
static var db: SQLite

const DB_PATH = "user://rpggame.db"

static func get_instance() -> SQLiteManager:
	if instance == null:
		instance = SQLiteManager.new()
	return instance

func _init():
	if db == null:
		db = SQLite.new()
		_initialize_database()

func _initialize_database():
	# 设置数据库路径
	db.path = DB_PATH
	db.verbosity_level = SQLite.NORMAL
	
	# 打开或创建数据库
	if not db.open_db():
		push_error("无法打开数据库: " + DB_PATH + " - " + db.error_message)
		return
	
	# 创建所有表
	_create_tables()
	
	print("数据库初始化完成")

func _create_tables():
	var tables = [
		_get_worlds_table_sql(),
		_get_games_table_sql(),
		_get_chapters_table_sql(),
		_get_goals_table_sql(),
		_get_subgoals_table_sql(),
		_get_goal_anchors_table_sql(),
		_get_characters_table_sql(),
		_get_chapter_character_instances_table_sql(),
		_get_character_chapter_info_table_sql(),
		_get_chapter_participants_table_sql(),
		_get_maps_table_sql(),
		_get_buildings_table_sql(),
		_get_props_table_sql(),
		_get_sessions_table_sql(),
		_get_authors_table_sql(),
		_get_game_interactions_table_sql()
	]
	
	for table_sql in tables:
		if not db.query(table_sql):
			push_error("创建表失败: " + table_sql + " - " + db.error_message)
	
	_create_indexes()

func _get_worlds_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS worlds (
		id INTEGER PRIMARY KEY,
		world_id TEXT UNIQUE NOT NULL,
		name TEXT NOT NULL,
		user_id TEXT NOT NULL,
		world_view TEXT,
		reference TEXT,
		knowledge_details TEXT,
		status TEXT DEFAULT 'normal',
		version INTEGER DEFAULT 1,
		characters_map TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	"""

func _get_games_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS games (
		id INTEGER PRIMARY KEY,
		game_id TEXT UNIQUE NOT NULL,
		name TEXT NOT NULL,
		category TEXT,
		background TEXT,
		intro TEXT,
		image TEXT,
		lang TEXT,
		genre TEXT,
		user_id TEXT NOT NULL,
		moderation_level TEXT,
		background_musics TEXT,
		use_shared_memory BOOLEAN DEFAULT FALSE,
		mechanics TEXT,
		operation_name TEXT,
		initialize_2d_status BOOLEAN DEFAULT FALSE,
		moderate_type TEXT,
		game_tags TEXT,
		social_references TEXT,
		source_template_id TEXT,
		image_style TEXT,
		in_public_mode BOOLEAN DEFAULT FALSE,
		editors TEXT,
		create_source TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	"""

func _get_chapters_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS chapters (
		id INTEGER PRIMARY KEY,
		chapter_id TEXT UNIQUE NOT NULL,
		game_id TEXT NOT NULL,
		name TEXT NOT NULL,
		background TEXT,
		intro TEXT,
		image TEXT,
		background_audio TEXT,
		ending_audio TEXT,
		map_url TEXT,
		background_musics TEXT,
		init_dialogue TEXT,
		lore_list TEXT,
		endings TEXT,
		no_goal BOOLEAN DEFAULT FALSE,
		goal_displayed TEXT,
		all_trigger_fail BOOLEAN DEFAULT FALSE,
		FOREIGN KEY (game_id) REFERENCES games(game_id)
	);
	"""

func _get_goals_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS goals (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		chapter_id TEXT NOT NULL,
		goal_key TEXT NOT NULL,
		goal_value TEXT,
		FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id)
	);
	"""

func _get_subgoals_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS subgoals (
		subgoal_id TEXT PRIMARY KEY,
		goal_id INTEGER NOT NULL,
		subgoal TEXT,
		FOREIGN KEY (goal_id) REFERENCES goals(id)
	);
	"""

func _get_goal_anchors_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS goal_anchors (
		anchor_id TEXT PRIMARY KEY,
		subgoal_id TEXT NOT NULL,
		affiliate TEXT,
		anchor_name TEXT,
		character_id TEXT,
		affiliate_type TEXT,
		anchor_init_value TEXT,
		anchor_goal_reached_value TEXT,
		FOREIGN KEY (subgoal_id) REFERENCES subgoals(subgoal_id)
	);
	"""

func _get_characters_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS characters (
		id INTEGER PRIMARY KEY,
		character_id TEXT UNIQUE NOT NULL,
		world_id TEXT NOT NULL,
		name TEXT NOT NULL,
		type TEXT NOT NULL,
		avatar TEXT,
		phases TEXT,
		voice_profile TEXT,
		opening_line TEXT,
		intro TEXT,
		character_tags TEXT,
		image_references TEXT,
		modules TEXT,
		appearance TEXT,
		texture TEXT,
		max_epochs TEXT DEFAULT "90",
		prompt TEXT,
		plugins TEXT,
		model_config TEXT,
		game_info TEXT,
		sprite_url TEXT,
		pronouns TEXT,
		age TEXT,
		background TEXT,
		traits TEXT,
		tone TEXT,
		interests TEXT,
		response_emojis BOOLEAN DEFAULT FALSE,
		response_gestures BOOLEAN DEFAULT FALSE,
		dialogue_reference TEXT,
		creator TEXT,
		creator_notes TEXT,
		version INTEGER DEFAULT 0,
		module_details TEXT,
		entries TEXT,
		user_id TEXT,
		persona_id TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (world_id) REFERENCES worlds(world_id)
	);
	"""

func _get_chapter_character_instances_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS chapter_character_instances (
		id INTEGER PRIMARY KEY,
		chapter_id TEXT NOT NULL,
		character_id TEXT NOT NULL,
		hp INTEGER DEFAULT 100,
		mp INTEGER DEFAULT 100,
		unit_type TEXT,
		is_init BOOLEAN DEFAULT TRUE,
		spawn_x REAL,
		spawn_y REAL,
		talk_value TEXT,
		action_key TEXT,
		is_patrol BOOLEAN DEFAULT FALSE,
		patrol_range INTEGER DEFAULT 60,
		patrol_range_type INTEGER DEFAULT 0,
		emoji TEXT,
		emoji_desc TEXT,
		emoji_summary TEXT,
		action_id TEXT,
		base_position_x REAL,
		base_position_y REAL,
		talk_topic TEXT,
		talk_topic_emoji TEXT,
		arrived_target_id TEXT,
		still_time INTEGER DEFAULT 0,
		patrol_timer INTEGER DEFAULT 30000,
		current_x REAL,
		current_y REAL,
		functions TEXT,
		chapter_specific_config TEXT,
		control_type INTEGER,
		client_session_id TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id),
		FOREIGN KEY (character_id) REFERENCES characters(character_id),
		UNIQUE(chapter_id, character_id)
	);
	"""

func _get_character_chapter_info_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS character_chapter_info (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		character_id TEXT NOT NULL,
		chapter_id TEXT NOT NULL,
		emotion TEXT,
		recent_ongoing TEXT,
		personal_setting TEXT,
		FOREIGN KEY (character_id) REFERENCES characters(character_id),
		FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id),
		UNIQUE(character_id, chapter_id)
	);
	"""

func _get_chapter_participants_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS chapter_participants (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		chapter_id TEXT NOT NULL,
		character_id TEXT NOT NULL,
		name TEXT NOT NULL,
		FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id),
		FOREIGN KEY (character_id) REFERENCES characters(character_id),
		UNIQUE(chapter_id, character_id)
	);
	"""

func _get_maps_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS maps (
		map_id TEXT PRIMARY KEY,
		game_id TEXT NOT NULL,
		chapter_id TEXT,
		name TEXT,
		map_file_path TEXT NOT NULL,
		is_active BOOLEAN DEFAULT TRUE,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (game_id) REFERENCES games(game_id),
		FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id)
	);
	"""

func _get_buildings_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS buildings (
		id INTEGER PRIMARY KEY,
		building_id TEXT UNIQUE NOT NULL,
		name TEXT NOT NULL,
		entity_id TEXT,
		user_id TEXT,
		map_id TEXT NOT NULL,
		category TEXT,
		chapter_id TEXT NOT NULL,
		game_id TEXT NOT NULL,
		appearance TEXT,
		width INTEGER,
		height INTEGER,
		spawn_x REAL,
		spawn_y REAL,
		x REAL NOT NULL,
		y REAL NOT NULL,
		texture TEXT,
		functions TEXT,
		depth INTEGER DEFAULT 1,
		interaction TEXT,
		is_init BOOLEAN DEFAULT TRUE,
		display_width INTEGER,
		display_height INTEGER,
		rotation REAL DEFAULT 0,
		visible BOOLEAN DEFAULT TRUE,
		FOREIGN KEY (map_id) REFERENCES maps(map_id),
		FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id),
		FOREIGN KEY (game_id) REFERENCES games(game_id)
	);
	"""

func _get_props_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS props (
		id INTEGER PRIMARY KEY,
		prop_id TEXT UNIQUE NOT NULL,
		game_id TEXT NOT NULL,
		chapter_id TEXT,
		name TEXT NOT NULL,
		type TEXT,
		description TEXT,
		image_url TEXT,
		properties TEXT,
		x REAL,
		y REAL,
		is_active BOOLEAN DEFAULT TRUE,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (game_id) REFERENCES games(game_id),
		FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id)
	);
	"""

func _get_sessions_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS sessions (
		session_id TEXT PRIMARY KEY,
		channel_id TEXT,
		game_id TEXT NOT NULL,
		chapter_id TEXT,
		source TEXT,
		last_message_id TEXT,
		app_id TEXT,
		type INTEGER,
		status INTEGER,
		create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
		update_time DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (game_id) REFERENCES games(game_id),
		FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id)
	);
	"""

func _get_authors_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS authors (
		user_id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		picture TEXT,
		status INTEGER DEFAULT 1,
		provider TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	"""

func _get_game_interactions_table_sql() -> String:
	return """
	CREATE TABLE IF NOT EXISTS game_interactions (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		game_id TEXT NOT NULL,
		played_count INTEGER DEFAULT 0,
		msg_count INTEGER DEFAULT 0,
		template_count INTEGER DEFAULT 0,
		chats_end_time DATETIME,
		last_play_time DATETIME,
		FOREIGN KEY (game_id) REFERENCES games(game_id)
	);
	"""

func _create_indexes():
	var indexes = [
		"CREATE INDEX IF NOT EXISTS idx_worlds_user_id ON worlds(user_id);",
		"CREATE INDEX IF NOT EXISTS idx_games_user_id ON games(user_id);",
		"CREATE INDEX IF NOT EXISTS idx_chapters_game_id ON chapters(game_id);",
		"CREATE INDEX IF NOT EXISTS idx_characters_world_id ON characters(world_id);",
		"CREATE INDEX IF NOT EXISTS idx_characters_character_id ON characters(character_id);",
		"CREATE INDEX IF NOT EXISTS idx_characters_type ON characters(type);",
		"CREATE INDEX IF NOT EXISTS idx_chapter_character_instances_chapter_id ON chapter_character_instances(chapter_id);",
		"CREATE INDEX IF NOT EXISTS idx_chapter_character_instances_character_id ON chapter_character_instances(character_id);",
		"CREATE INDEX IF NOT EXISTS idx_character_chapter_info_character_id ON character_chapter_info(character_id);",
		"CREATE INDEX IF NOT EXISTS idx_character_chapter_info_chapter_id ON character_chapter_info(chapter_id);",
		"CREATE INDEX IF NOT EXISTS idx_chapter_participants_chapter_id ON chapter_participants(chapter_id);",
		"CREATE INDEX IF NOT EXISTS idx_chapter_participants_character_id ON chapter_participants(character_id);",
		"CREATE INDEX IF NOT EXISTS idx_buildings_map_id ON buildings(map_id);",
		"CREATE INDEX IF NOT EXISTS idx_buildings_chapter_id ON buildings(chapter_id);",
		"CREATE INDEX IF NOT EXISTS idx_buildings_game_id ON buildings(game_id);",
		"CREATE INDEX IF NOT EXISTS idx_buildings_building_id ON buildings(building_id);",
		"CREATE INDEX IF NOT EXISTS idx_props_game_id ON props(game_id);",
		"CREATE INDEX IF NOT EXISTS idx_props_chapter_id ON props(chapter_id);",
		"CREATE INDEX IF NOT EXISTS idx_goals_chapter_id ON goals(chapter_id);",
		"CREATE INDEX IF NOT EXISTS idx_subgoals_goal_id ON subgoals(goal_id);",
		"CREATE INDEX IF NOT EXISTS idx_goal_anchors_subgoal_id ON goal_anchors(subgoal_id);",
		"CREATE INDEX IF NOT EXISTS idx_sessions_game_id ON sessions(game_id);",
		"CREATE INDEX IF NOT EXISTS idx_sessions_chapter_id ON sessions(chapter_id);",
		"CREATE INDEX IF NOT EXISTS idx_maps_game_id ON maps(game_id);",
		"CREATE INDEX IF NOT EXISTS idx_maps_chapter_id ON maps(chapter_id);",
		"CREATE INDEX IF NOT EXISTS idx_game_interactions_game_id ON game_interactions(game_id);"
	]
	
	for index_sql in indexes:
		if not db.query(index_sql):
			push_error("创建索引失败: " + index_sql + " - " + db.error_message)

# 执行查询
static func execute_query(query: String, params: Array = []) -> Array:
	var db_instance = get_instance().db
	if params.size() > 0:
		if not db_instance.query_with_bindings(query, params):
			push_error("查询执行失败: " + query + " - " + db_instance.error_message)
			return []
	else:
		if not db_instance.query(query):
			push_error("查询执行失败: " + query + " - " + db_instance.error_message)
			return []
	return db_instance.query_result

# 执行插入/更新/删除操作
static func execute_non_query(query: String, params: Array = []) -> bool:
	var db_instance = get_instance().db
	var success = false
	if params.size() > 0:
		success = db_instance.query_with_bindings(query, params)
	else:
		success = db_instance.query(query)
	
	if not success:
		push_error("执行失败: " + query + " - " + db_instance.error_message)
	
	return success

# 开始事务
static func begin_transaction() -> bool:
	var success = get_instance().db.query("BEGIN TRANSACTION;")
	if not success:
		push_error("开始事务失败: " + get_instance().db.error_message)
	return success

# 提交事务
static func commit_transaction() -> bool:
	var success = get_instance().db.query("COMMIT;")
	if not success:
		push_error("提交事务失败: " + get_instance().db.error_message)
	return success

# 回滚事务
static func rollback_transaction() -> bool:
	var success = get_instance().db.query("ROLLBACK;")
	if not success:
		push_error("回滚事务失败: " + get_instance().db.error_message)
	return success

# 关闭数据库连接
static func close():
	if db and db.close_db():
		print("数据库连接已关闭")
	db = null
	instance = null 
