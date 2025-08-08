class_name GameRepository
extends RefCounted

# 创建游戏
static func create(game: GameModel) -> bool:
	if not game.validate():
		push_error("游戏数据验证失败")
		return false
	
	var query = """
	INSERT INTO games (game_id, name, category, background, intro, image, lang, genre, user_id, 
					   moderation_level, background_musics, use_shared_memory, mechanics, operation_name,
					   initialize_2d_status, moderate_type, game_tags, social_references, source_template_id,
					   image_style, in_public_mode, editors, create_source)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	"""
	
	var params = [
		game.game_id, game.name, game.category, game.background, game.intro,
		game.image, game.lang, game.genre, game.user_id, game.moderation_level,
		JSON.stringify(game.background_musics) if game.background_musics.size() > 0 else "[]",
		game.use_shared_memory, game.mechanics, game.operation_name, game.initialize_2d_status,
		game.moderate_type, JSON.stringify(game.game_tags), JSON.stringify(game.social_references),
		game.source_template_id, game.image_style, game.in_public_mode, 
		JSON.stringify(game.editors), game.create_source
	]
	
	return SQLiteManager.execute_non_query(query, params)

# 根据game_id获取游戏
static func get_by_game_id(game_id: String) -> GameModel:
	var query = "SELECT * FROM games WHERE game_id = ?"
	var results = SQLiteManager.execute_query(query, [game_id])
	
	if results.size() > 0:
		return GameModel.new(results[0])
	
	return null

# 根据用户ID获取游戏列表
static func get_by_user_id(user_id: String) -> Array:
	var query = "SELECT * FROM games WHERE user_id = ? ORDER BY created_at DESC"
	var results = SQLiteManager.execute_query(query, [user_id])
	
	var games: Array = []
	for result in results:
		games.append(GameModel.new(result))
	
	return games

# 更新游戏
static func update(game: GameModel) -> bool:
	if not game.validate():
		push_error("游戏数据验证失败")
		return false
	
	var query = """
	UPDATE games 
	SET name = ?, category = ?, background = ?, intro = ?, image = ?, lang = ?, genre = ?,
		moderation_level = ?, background_musics = ?, use_shared_memory = ?, mechanics = ?,
		operation_name = ?, initialize_2d_status = ?, moderate_type = ?, game_tags = ?,
		social_references = ?, image_style = ?, in_public_mode = ?, editors = ?,
		updated_at = CURRENT_TIMESTAMP
	WHERE game_id = ?
	"""
	
	var params = [
		game.name, game.category, game.background, game.intro, game.image,
		game.lang, game.genre, game.moderation_level,
		JSON.stringify(game.background_musics) if game.background_musics.size() > 0 else "[]",
		game.use_shared_memory, game.mechanics, game.operation_name, game.initialize_2d_status,
		game.moderate_type, JSON.stringify(game.game_tags), JSON.stringify(game.social_references),
		game.image_style, game.in_public_mode, JSON.stringify(game.editors),
		game.game_id
	]
	
	return SQLiteManager.execute_non_query(query, params)

# 删除游戏
static func delete(game_id: String) -> bool:
	var query = "DELETE FROM games WHERE game_id = ?"
	return SQLiteManager.execute_non_query(query, [game_id])

# 检查游戏是否存在
static func exists(game_id: String) -> bool:
	var query = "SELECT COUNT(*) as count FROM games WHERE game_id = ?"
	var results = SQLiteManager.execute_query(query, [game_id])
	
	if results.size() > 0:
		return results[0].count > 0
	
	return false

# 获取所有游戏
static func get_all() -> Array:
	var query = "SELECT * FROM games ORDER BY created_at DESC"
	var results = SQLiteManager.execute_query(query)
	
	var games: Array = []
	for result in results:
		games.append(GameModel.new(result))
	
	return games 
