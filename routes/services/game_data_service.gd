# game_data_service.gd
# 游戏数据服务 - 从数据库查询数据并拼装成GY3MCVANW.json格式
class_name GameDataService
extends RefCounted

# 导出游戏数据（主要入口点）
static func export_game_data(context: Dictionary) -> Dictionary:
	var game_id = context.query_params.get("game_id", "")
	
	if game_id.is_empty():
		return {
			"error": "缺少必需的参数 game_id",
			"code": 400
		}
	
	var result = await export_game_data_for_game_id(game_id)
	return result

static func export_game_data_for_game_id(game_id: String) -> Dictionary:
	print("🎮 开始导出游戏数据, game_id: %s" % game_id)
	
	# 查询游戏基本信息
	var game_info = _get_game_info(game_id)
	if game_info.is_empty():
		return {
			"error": "未找到指定的游戏: " + game_id,
			"code": 404
		}
	
	# 拼装完整的游戏数据
	var game_data = {
		"game_info": game_info,
		"buildings": _get_game_buildings(game_id),
		"props": _get_game_props(game_id),
		"session_info": _get_game_session_info(game_id)
	}
	
	print("✅ 游戏数据导出完成")
	print("📊 数据统计 - 章节数: %d" % game_info.get("chapters", []).size())
	print("📊 建筑数: %d" % game_data.buildings.size())
	print("📊 道具数: %d" % game_data.props.size()) 
	print("📊 会话数: %d" % game_data.session_info.size())
	if game_info.has("chapters") and game_info.chapters.size() > 0:
		print("📊 第一章角色数: %d" % game_info.chapters[0].get("characters", []).size())
	
	# 根据chapter中的map_url的远程json地址，获取map_data，并拼装到game_data中
	var map_data = {}
	if game_info.has("chapters") and game_info.chapters.size() > 0:
		var map_url = game_info.chapters[0].map_url
		print("map_url", map_url)
		if !map_url.is_empty():
			map_data = await Request._http_get(map_url)
			if map_data == null:
				print("map_data is null")
	game_data.map_data = map_data

	return game_data

# 获取游戏基本信息和所有章节
static func _get_game_info(game_id: String) -> Dictionary:
	# 查询游戏基本信息
	var game_query = """
		SELECT * FROM games
		WHERE game_id = ?
	"""
	
	var game_result = SQLiteManager.execute_query(game_query, [game_id])
	if game_result.is_empty():
		return {}
	
	var game_row = game_result[0]
	
	# 构建游戏基本信息
	var game_info = {
		"name": game_row.get("name", ""),
		"game_id": game_row.get("game_id", ""),
		"category": game_row.get("category", ""),
		"background": game_row.get("background", ""),
		"intro": game_row.get("intro", ""),
		"image": game_row.get("image", ""),
		"lang": game_row.get("lang", ""),
		"genre": game_row.get("genre", ""),
		"user_id": game_row.get("user_id", ""),
		"moderation_level": game_row.get("moderation_level", "G"),
		"background_musics": _parse_json_field(game_row.get("background_musics", "[]"), []),
		"use_shared_memory": _to_bool(game_row.get("use_shared_memory", false)),
		"chapters": _get_chapters(game_id),
		"updated_at": game_row.get("updated_at", ""),
		"created_at": game_row.get("created_at", "")
	}
	
	return game_info

# 获取游戏的所有章节
static func _get_chapters(game_id: String) -> Array:
	var chapters_query = """
		SELECT * FROM chapters 
		WHERE game_id = ?
		ORDER BY chapter_id
	"""
	
	var chapters_result = SQLiteManager.execute_query(chapters_query, [game_id])
	var chapters = []
	
	for chapter_row in chapters_result:
		var chapter_data = {
			"name": chapter_row.get("name", ""),
			"chapter_id": chapter_row.get("chapter_id", ""),
			"background": chapter_row.get("background", ""),
			"intro": chapter_row.get("intro", ""),
			"image": chapter_row.get("image", ""),
			"background_audio": chapter_row.get("background_audio", ""),
			"ending_audio": chapter_row.get("ending_audio", ""),
			"map_url": chapter_row.get("map_url", ""),
			"background_musics": _parse_json_field(chapter_row.get("background_musics", "[]"), []),
			"goals": _get_chapter_goals(chapter_row.get("chapter_id", "")),
			"goal_info": {
				"no_goal": _to_bool(chapter_row.get("no_goal", false)),
				"goal_displayed": chapter_row.get("goal_displayed", ""),
				"all_trigger_fail": _to_bool(chapter_row.get("all_trigger_fail", false))
			},
			"characters": _get_chapter_characters(chapter_row.get("chapter_id", "")),
			"players": _get_chapter_players(chapter_row.get("chapter_id", ""))
		}
		chapters.append(chapter_data)
	
	return chapters

# 获取章节的目标
static func _get_chapter_goals(chapter_id: String) -> Array:
	var goals_query = """
		SELECT * FROM goals 
		WHERE chapter_id = ?
		ORDER BY goal_key
	"""
	
	var goals_result = SQLiteManager.execute_query(goals_query, [chapter_id])
	var goals = []
	
	for goal_row in goals_result:
		var goal_data = {
			"key": goal_row.get("goal_key", ""),
			"value": goal_row.get("goal_value", ""),
			"subgoals": _get_goal_subgoals(goal_row.get("id", 0))
		}
		goals.append(goal_data)
	
	return goals

# 获取目标的子目标
static func _get_goal_subgoals(goal_id: int) -> Array:
	var subgoals_query = """
		SELECT * FROM subgoals 
		WHERE goal_id = ?
		ORDER BY subgoal_id
	"""
	
	var subgoals_result = SQLiteManager.execute_query(subgoals_query, [goal_id])
	var subgoals = []
	
	for subgoal_row in subgoals_result:
		var subgoal_data = {
			"id": subgoal_row.get("subgoal_id", ""),
			"subgoal": subgoal_row.get("subgoal", "")
		}
		
		# 获取目标锚点
		var anchors = _get_subgoal_anchors(subgoal_row.get("subgoal_id", ""))
		if not anchors.is_empty():
			subgoal_data["goal_anchor"] = anchors
		
		subgoals.append(subgoal_data)
	
	return subgoals

# 获取子目标的锚点
static func _get_subgoal_anchors(subgoal_id: String) -> Array:
	var anchors_query = """
		SELECT * FROM goal_anchors 
		WHERE subgoal_id = ?
		ORDER BY anchor_id
	"""
	
	var anchors_result = SQLiteManager.execute_query(anchors_query, [subgoal_id])
	var anchors = []
	
	for anchor_row in anchors_result:
		var anchor_data = {
			"id": anchor_row.get("anchor_id", ""),
			"affiliate": anchor_row.get("affiliate", ""),
			"anchor_name": anchor_row.get("anchor_name", ""),
			"character_id": anchor_row.get("character_id", ""),
			"affiliate_type": anchor_row.get("affiliate_type", ""),
			"anchor_init_value": anchor_row.get("anchor_init_value", ""),
			"anchor_goal_reached_value": anchor_row.get("anchor_goal_reached_value", "")
		}
		anchors.append(anchor_data)
	
	return anchors

# 获取章节的角色（从character表和chapter_character_instances表联合查询）
static func _get_chapter_characters(chapter_id: String) -> Array:
	# 只取unit_type为NPC的角色
	var characters_query = """
		SELECT 
			c.character_id as id,
			c.name,
			c.type,
			c.avatar,
			c.phases,
			c.voice_profile,
			c.opening_line,
			c.intro,
			c.character_tags,
			c.image_references,
			c.modules,
			c.appearance,
			c.texture,
			cci.hp,
			cci.mp,
			cci.spawn_x,
			cci.spawn_y,
			cci.current_x,
			cci.current_y,
			cci.unit_type,
			cci.is_init,
			cci.talk_value,
			cci.action_key,
			cci.is_patrol,
			cci.patrol_range,
			cci.emoji,
			cci.base_position_x,
			cci.base_position_y,
			cci.talk_topic,
			cci.arrived_target_id,
			cci.still_time,
			cci.patrol_timer,
			cci.functions,
			cci.control_type,
			cci.client_session_id,
			cci.chapter_specific_config
		FROM characters c
		INNER JOIN chapter_character_instances cci ON c.character_id = cci.character_id
		WHERE cci.chapter_id = ? AND cci.unit_type = 'NPC'
		ORDER BY c.character_id
	"""
	
	var characters_result = SQLiteManager.execute_query(characters_query, [chapter_id])
	var characters = []
	
	for char_row in characters_result:
		var character_data = {
			"id": char_row.get("id", ""),
			"name": char_row.get("name", ""),
			"type": char_row.get("type", "npc"),
			"avatar": char_row.get("avatar", ""),
			"phases": _parse_json_field(char_row.get("phases", "[\"default\"]"), ["default"]),
			"voice_profile": char_row.get("voice_profile", ""),
			"opening_line": char_row.get("opening_line", ""),
			"intro": char_row.get("intro", ""),
			"character_tags": _parse_json_field(char_row.get("character_tags", "[]"), []),
			"image_references": _parse_json_field(char_row.get("image_references", "[]"), []),
			"modules": _parse_json_field(char_row.get("modules", "[]"), []),
			"appearance": char_row.get("appearance", ""),
			"texture": char_row.get("texture", ""),
			"hp": char_row.get("hp", 100),
			"mp": char_row.get("mp", 100),
			"spawn_x": char_row.get("spawn_x", 0),
			"spawn_y": char_row.get("spawn_y", 0),
			"current_x": char_row.get("current_x", 0),
			"current_y": char_row.get("current_y", 0),
			"unit_type": char_row.get("unit_type", ""),
			"is_init": _to_bool(char_row.get("is_init", false)),
			"talk_value": char_row.get("talk_value", ""),
			"action_key": char_row.get("action_key", ""),
			"is_patrol": _to_bool(char_row.get("is_patrol", false)),
			"patrol_range": char_row.get("patrol_range", 0),
			"emoji": char_row.get("emoji", ""),
			"base_position_x": char_row.get("base_position_x", 0),
			"base_position_y": char_row.get("base_position_y", 0),
			"talk_topic": char_row.get("talk_topic", ""),
			"arrived_target_id": char_row.get("arrived_target_id", ""),
			"still_time": char_row.get("still_time", 0),
			"patrol_timer": char_row.get("patrol_timer", 0),
			"functions": _parse_json_field(char_row.get("functions", "[]"), []),
			"control_type": char_row.get("control_type", ""),
			"client_session_id": char_row.get("client_session_id", "")
		}
		
		# 处理章节特定配置
		var chapter_config = _parse_json_field(char_row.get("chapter_specific_config", "{}"), {})
		if chapter_config != null and not chapter_config.is_empty():
			# 合并章节特定配置到角色数据中
			for key in chapter_config.keys():
				character_data[key] = chapter_config[key]
		
		characters.append(character_data)
	
	return characters

# 获取章节的玩家（玩家也可能是角色的一种特殊类型）
static func _get_chapter_players(chapter_id: String) -> Array:
	# 查询类型为player的角色，数据格式和_get_chapter_characters一样，只是unit_type为Player
	# 只取unit_type为NPC的角色
	var players_query = """
		SELECT 
			c.character_id as id,
			c.name,
			c.type,
			c.avatar,
			c.phases,
			c.voice_profile,
			c.opening_line,
			c.intro,
			c.character_tags,
			c.image_references,
			c.modules,
			c.appearance,
			c.texture,
			cci.hp,
			cci.mp,
			cci.spawn_x,
			cci.spawn_y,
			cci.current_x,
			cci.current_y,
			cci.unit_type,
			cci.is_init,
			cci.talk_value,
			cci.action_key,
			cci.is_patrol,
			cci.patrol_range,
			cci.emoji,
			cci.base_position_x,
			cci.base_position_y,
			cci.talk_topic,
			cci.arrived_target_id,
			cci.still_time,
			cci.patrol_timer,
			cci.functions,
			cci.control_type,
			cci.client_session_id,
			cci.chapter_specific_config
		FROM characters c
		INNER JOIN chapter_character_instances cci ON c.character_id = cci.character_id
		WHERE cci.chapter_id = ? AND cci.unit_type = 'Player'
		ORDER BY c.character_id
	"""
	
	var players_result = SQLiteManager.execute_query(players_query, [chapter_id])
	var players = []
	
	for player_row in players_result:
		var player_data = {
			"id": player_row.get("id", ""),
			"name": player_row.get("name", ""),
			"type": player_row.get("type", "npc"),
			"avatar": player_row.get("avatar", ""),
			"phases": _parse_json_field(player_row.get("phases", "[\"default\"]"), ["default"]),
			"voice_profile": player_row.get("voice_profile", ""),
			"opening_line": player_row.get("opening_line", ""),
			"intro": player_row.get("intro", ""),
			"character_tags": _parse_json_field(player_row.get("character_tags", "[]"), []),
			"image_references": _parse_json_field(player_row.get("image_references", "[]"), []),
			"modules": _parse_json_field(player_row.get("modules", "[]"), []),
			"appearance": player_row.get("appearance", ""),
			"texture": player_row.get("texture", ""),
			"hp": player_row.get("hp", 100),
			"mp": player_row.get("mp", 100),
			"spawn_x": player_row.get("spawn_x", 0),
			"spawn_y": player_row.get("spawn_y", 0),
			"current_x": player_row.get("current_x", 0),
			"current_y": player_row.get("current_y", 0),
			"unit_type": player_row.get("unit_type", ""),
			"is_init": _to_bool(player_row.get("is_init", false)),
			"talk_value": player_row.get("talk_value", ""),
			"action_key": player_row.get("action_key", ""),
			"is_patrol": _to_bool(player_row.get("is_patrol", false)),
			"patrol_range": player_row.get("patrol_range", 0),
			"emoji": player_row.get("emoji", ""),
			"base_position_x": player_row.get("base_position_x", 0),
			"base_position_y": player_row.get("base_position_y", 0),
			"talk_topic": player_row.get("talk_topic", ""),
			"arrived_target_id": player_row.get("arrived_target_id", ""),
			"still_time": player_row.get("still_time", 0),
			"patrol_timer": player_row.get("patrol_timer", 0),
			"functions": _parse_json_field(player_row.get("functions", "[]"), []),
			"control_type": player_row.get("control_type", ""),
			"client_session_id": player_row.get("client_session_id", "")
		}
		
		# 处理章节特定配置
		var chapter_config = _parse_json_field(player_row.get("chapter_specific_config", "{}"), {})
		if chapter_config != null and not chapter_config.is_empty():
			# 合并章节特定配置到角色数据中
			for key in chapter_config.keys():
				player_data[key] = chapter_config[key]
		
		players.append(player_data)
	
	return players

# 解析JSON字段，如果解析失败返回指定的默认值
static func _parse_json_field(json_string: Variant, default_value: Variant = null) -> Variant:
	# 如果输入是 null 或空字符串，返回默认值
	if json_string == null or (json_string is String and (json_string.is_empty() or json_string == "null")):
		return default_value
	
	# 确保输入是字符串类型
	var json_str = str(json_string) if json_string != null else ""
	if json_str.is_empty():
		return default_value
	
	var json = JSON.new()
	var parse_result = json.parse(json_str)
	
	if parse_result == OK:
		return json.data
	else:
		push_warning("Failed to parse JSON: %s" % json_str)
		return default_value

# 安全转换布尔值
static func _to_bool(value: Variant) -> bool:
	if value is bool:
		return value
	elif value is int:
		return value != 0
	elif value is String:
		return value.to_lower() in ["true", "1", "yes"]
	else:
		return false

# 获取游戏的建筑数据
static func _get_game_buildings(game_id: String) -> Array:
	var buildings_query = """
		SELECT * FROM buildings 
		WHERE game_id = ?
		ORDER BY building_id
	"""
	
	var buildings_result = SQLiteManager.execute_query(buildings_query, [game_id])
	var buildings = []
	
	for building_row in buildings_result:
		var building_data = {
			"building_id": building_row.get("building_id", ""),
			"name": building_row.get("name", ""),
			"entity_id": building_row.get("entity_id", ""),
			"user_id": building_row.get("user_id", ""),
			"map_id": building_row.get("map_id", ""),
			"category": building_row.get("category", ""),
			"chapter_id": building_row.get("chapter_id", ""),
			"game_id": building_row.get("game_id", ""),
			"appearance": _parse_json_field(building_row.get("appearance", "{}"), {}),
			"width": building_row.get("width", 0),
			"height": building_row.get("height", 0),
			"spawn_x": building_row.get("spawn_x", 0),
			"spawn_y": building_row.get("spawn_y", 0),
			"x": building_row.get("x", 0),
			"y": building_row.get("y", 0),
			"texture": building_row.get("texture", ""),
			"functions": _parse_json_field(building_row.get("functions", "[]"), []),
			"depth": building_row.get("depth", 0),
			"interaction": _parse_json_field(building_row.get("interaction", "{}"), {}),
			"is_init": _to_bool(building_row.get("is_init", false)),
			"display_width": building_row.get("display_width", 0),
			"display_height": building_row.get("display_height", 0),
			"rotation": building_row.get("rotation", 0),
			"visible": _to_bool(building_row.get("visible", true))
		}
		buildings.append(building_data)
	
	return buildings

# 获取游戏的道具数据
static func _get_game_props(game_id: String) -> Array:
	var props_query = """
		SELECT * FROM props 
		WHERE game_id = ?
		ORDER BY prop_id
	"""
	
	var props_result = SQLiteManager.execute_query(props_query, [game_id])
	var props = []
	
	for prop_row in props_result:
		var prop_data = {
			"prop_id": prop_row.get("prop_id", ""),
			"name": prop_row.get("name", ""),
			"entity_id": prop_row.get("entity_id", ""),
			"user_id": prop_row.get("user_id", ""),
			"map_id": prop_row.get("map_id", ""),
			"category": prop_row.get("category", ""),
			"chapter_id": prop_row.get("chapter_id", ""),
			"game_id": prop_row.get("game_id", ""),
			"appearance": _parse_json_field(prop_row.get("appearance", "{}"), {}),
			"width": prop_row.get("width", 0),
			"height": prop_row.get("height", 0),
			"spawn_x": prop_row.get("spawn_x", 0),
			"spawn_y": prop_row.get("spawn_y", 0),
			"x": prop_row.get("x", 0),
			"y": prop_row.get("y", 0),
			"texture": prop_row.get("texture", ""),
			"functions": _parse_json_field(prop_row.get("functions", "[]"), []),
			"depth": prop_row.get("depth", 0),
			"interaction": _parse_json_field(prop_row.get("interaction", "{}"), {}),
			"is_init": _to_bool(prop_row.get("is_init", false)),
			"display_width": prop_row.get("display_width", 0),
			"display_height": prop_row.get("display_height", 0),
			"rotation": prop_row.get("rotation", 0),
			"visible": _to_bool(prop_row.get("visible", true))
		}
		props.append(prop_data)
	
	return props

# 获取游戏的会话信息
static func _get_game_session_info(game_id: String) -> Array:
	var sessions_query = """
		SELECT * FROM sessions 
		WHERE game_id = ?
		ORDER BY session_id
	"""
	
	var sessions_result = SQLiteManager.execute_query(sessions_query, [game_id])
	var sessions = []
	
	for session_row in sessions_result:
		var session_data = {
			"session_id": session_row.get("session_id", ""),
			"player_id": session_row.get("player_id", ""),
			"character_id": session_row.get("character_id", ""),
			"game_id": session_row.get("game_id", ""),
			"chapter_id": session_row.get("chapter_id", ""),
			"user_id": session_row.get("user_id", ""),
			"connection_string": session_row.get("connection_string", ""),
			"ip": session_row.get("ip", ""),
			"port": session_row.get("port", ""),
			"is_active": _to_bool(session_row.get("is_active", false)),
			"created_at": session_row.get("created_at", ""),
			"updated_at": session_row.get("updated_at", "")
		}
		sessions.append(session_data)
	
	return sessions 
