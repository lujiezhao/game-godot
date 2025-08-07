class_name WorldRepository
extends RefCounted

# 创建世界
static func create(world: WorldModel) -> bool:
	if not world.validate():
		push_error("世界数据验证失败")
		return false
	
	var query = """
	INSERT INTO worlds (world_id, name, user_id, world_view, reference, knowledge_details, status, version, characters_map)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	"""
	
	var params = [
		world.world_id,
		world.name,
		world.user_id,
		world.world_view,
		world.reference,
		world.knowledge_details,
		world.status,
		world.version,
		JSON.stringify(world.characters_map)
	]
	
	return SQLiteManager.execute_non_query(query, params)

# 根据world_id获取世界
static func get_by_world_id(world_id: String) -> WorldModel:
	var query = "SELECT * FROM worlds WHERE world_id = ?"
	var results = SQLiteManager.execute_query(query, [world_id])
	
	if results.size() > 0:
		return WorldModel.new(results[0])
	
	return null

# 根据用户ID获取世界列表
static func get_by_user_id(user_id: String) -> Array[WorldModel]:
	var query = "SELECT * FROM worlds WHERE user_id = ? ORDER BY created_at DESC"
	var results = SQLiteManager.execute_query(query, [user_id])
	
	var worlds: Array[WorldModel] = []
	for result in results:
		worlds.append(WorldModel.new(result))
	
	return worlds

# 更新世界
static func update(world: WorldModel) -> bool:
	if not world.validate():
		push_error("世界数据验证失败")
		return false
	
	var query = """
	UPDATE worlds 
	SET name = ?, world_view = ?, reference = ?, knowledge_details = ?, 
	    status = ?, version = ?, characters_map = ?, updated_at = CURRENT_TIMESTAMP
	WHERE world_id = ?
	"""
	
	var params = [
		world.name,
		world.world_view,
		world.reference,
		world.knowledge_details,
		world.status,
		world.version,
		JSON.stringify(world.characters_map),
		world.world_id
	]
	
	return SQLiteManager.execute_non_query(query, params)

# 删除世界
static func delete(world_id: String) -> bool:
	var query = "DELETE FROM worlds WHERE world_id = ?"
	return SQLiteManager.execute_non_query(query, [world_id])

# 检查世界是否存在
static func exists(world_id: String) -> bool:
	var query = "SELECT COUNT(*) as count FROM worlds WHERE world_id = ?"
	var results = SQLiteManager.execute_query(query, [world_id])
	
	if results.size() > 0:
		return results[0].count > 0
	
	return false

# 获取所有世界
static func get_all() -> Array[WorldModel]:
	var query = "SELECT * FROM worlds ORDER BY created_at DESC"
	var results = SQLiteManager.execute_query(query)
	
	var worlds: Array[WorldModel] = []
	for result in results:
		worlds.append(WorldModel.new(result))
	
	return worlds 