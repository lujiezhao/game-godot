class_name JSONImporter
extends RefCounted

# 从JSON文件导入完整游戏数据
static func import_from_json_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("JSON文件不存在: " + file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("无法打开JSON文件: " + file_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("JSON解析失败: " + file_path)
		return false
	
	return import_game_data(json.data)

# 导入游戏数据
static func import_game_data(data: Dictionary) -> bool:
	# 开始事务
	if not SQLiteManager.begin_transaction():
		push_error("无法开始事务")
		return false
	
	var success = true
	
	# 导入世界信息
	if data.has("world_info") and success:
		success = _import_world_info(data.world_info)
	
	# 导入游戏信息
	if data.has("game_info") and success:
		success = _import_game_info(data.game_info)
	
	# 导入地图数据（如果存在）
	if data.has("map_data") and data.map_data != {} and success:
		success = _import_map_data(data.map_data, data.game_info.game_id)
	
	# 导入会话信息
	if data.has("session_info") and success:
		success = _import_session_info(data.session_info)
	
	if success:
		SQLiteManager.commit_transaction()
		print("游戏数据导入成功")
	else:
		SQLiteManager.rollback_transaction()
		push_error("游戏数据导入失败，已回滚")
	
	return success

# 导入世界信息
static func _import_world_info(world_data: Dictionary) -> bool:
	var world = WorldModel.new(world_data)
	
	# 检查是否已存在
	if WorldRepository.exists(world.world_id):
		return WorldRepository.update(world)
	else:
		return WorldRepository.create(world)

# 导入游戏信息
static func _import_game_info(game_data: Dictionary) -> bool:
	var game = GameModel.new(game_data)
	
	var success = true
	
	# 导入游戏基本信息
	if GameRepository.exists(game.game_id):
		success = GameRepository.update(game)
	else:
		success = GameRepository.create(game)
	
	if not success:
		return false
	
	# 导入作者信息
	if game_data.has("author"):
		success = _import_author_info(game_data.author)
	
	if not success:
		return false
	
	# 导入游戏交互统计
	if game_data.has("interaction"):
		success = _import_game_interaction(game_data.interaction, game.game_id)
	
	if not success:
		return false
	
	# 导入章节数据
	if game_data.has("chapters"):
		for chapter_data in game_data.chapters:
			success = _import_chapter_data(chapter_data, game.game_id)
			if not success:
				break
	
	return success

# 导入作者信息
static func _import_author_info(author_data: Dictionary) -> bool:
	var query = """
	INSERT OR REPLACE INTO authors (user_id, name, picture, status, provider)
	VALUES (?, ?, ?, ?, ?)
	"""
	
	var params = [
		author_data.get("user_id", ""),
		author_data.get("name", ""),
		author_data.get("picture", ""),
		author_data.get("status", 1),
		author_data.get("provider", "")
	]
	
	return SQLiteManager.execute_non_query(query, params)

# 导入游戏交互统计
static func _import_game_interaction(interaction_data: Dictionary, game_id: String) -> bool:
	var query = """
	INSERT OR REPLACE INTO game_interactions (game_id, played_count, msg_count, template_count, chats_end_time, last_play_time)
	VALUES (?, ?, ?, ?, ?, ?)
	"""
	
	var params = [
		game_id,
		interaction_data.get("played_count", 0),
		interaction_data.get("msg_count", 0),
		interaction_data.get("template_count", 0),
		interaction_data.get("chats_end_time", ""),
		interaction_data.get("last_play_time", "")
	]
	
	return SQLiteManager.execute_non_query(query, params)

# 导入章节数据
static func _import_chapter_data(chapter_data: Dictionary, game_id: String) -> bool:
	# 导入章节基本信息
	var success = _import_chapter_basic_info(chapter_data, game_id)
	
	if not success:
		return false
	
	var chapter_id = chapter_data.get("chapter_id", "")
	
	# 导入目标数据
	if chapter_data.has("goals"):
		success = _import_goals_data(chapter_data.goals, chapter_id)
		if not success:
			return false
	
	# 导入角色数据
	if chapter_data.has("characters"):
		success = _import_characters_data(chapter_data.characters, chapter_id)
		if not success:
			return false
	
	# 导入玩家数据
	if chapter_data.has("players"):
		success = _import_players_data(chapter_data.players, chapter_id)
		if not success:
			return false
	
	# 导入角色章节信息
	if chapter_data.has("character_info"):
		success = _import_character_chapter_info(chapter_data.character_info, chapter_id)
		if not success:
			return false
	
	# 导入章节参与者
	if chapter_data.has("participants"):
		success = _import_chapter_participants(chapter_data.participants, chapter_id)
		if not success:
			return false
	
	# 导入建筑数据
	if chapter_data.has("buildings"):
		success = _import_buildings_data(chapter_data.buildings, chapter_id, game_id)
		if not success:
			return false
	
	# 导入道具数据
	if chapter_data.has("props"):
		success = _import_props_data(chapter_data.props, chapter_id, game_id)
		if not success:
			return false
	
	return true

# 导入章节基本信息
static func _import_chapter_basic_info(chapter_data: Dictionary, game_id: String) -> bool:
	var query = """
	INSERT OR REPLACE INTO chapters 
	(chapter_id, game_id, name, background, intro, image, background_audio, ending_audio,
	 map_url, background_musics, init_dialogue, lore_list, endings, no_goal, goal_displayed, all_trigger_fail)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	"""
	
	var params = [
		chapter_data.get("chapter_id", ""),
		game_id,
		chapter_data.get("name", ""),
		chapter_data.get("background", ""),
		chapter_data.get("intro", ""),
		chapter_data.get("image", ""),
		chapter_data.get("background_audio", ""),
		chapter_data.get("ending_audio", ""),
		chapter_data.get("map_url", ""),
		JSON.stringify(chapter_data.get("background_musics", [])),
		JSON.stringify(chapter_data.get("init_dialogue", [])),
		JSON.stringify(chapter_data.get("lore_list", [])),
		chapter_data.get("endings", ""),
		chapter_data.get("no_goal", false),
		chapter_data.get("goal_displayed", ""),
		chapter_data.get("all_trigger_fail", false)
	]
	
	return SQLiteManager.execute_non_query(query, params)

# 导入目标数据
static func _import_goals_data(goals_data: Array, chapter_id: String) -> bool:
	for goal_data in goals_data:
		var goal_query = """
		INSERT OR REPLACE INTO goals (chapter_id, goal_key, goal_value)
		VALUES (?, ?, ?)
		"""
		
		var goal_params = [
			chapter_id,
			goal_data.get("key", ""),
			goal_data.get("value", "")
		]
		
		if not SQLiteManager.execute_non_query(goal_query, goal_params):
			return false
		
		# 获取刚插入的goal_id
		var goal_id_query = "SELECT id FROM goals WHERE chapter_id = ? AND goal_key = ?"
		var goal_results = SQLiteManager.execute_query(goal_id_query, [chapter_id, goal_data.get("key", "")])
		
		if goal_results.size() == 0:
			return false
		
		var goal_id = goal_results[0].id
		
		# 导入子目标
		if goal_data.has("subgoals"):
			for subgoal_data in goal_data.subgoals:
				var subgoal_query = """
				INSERT OR REPLACE INTO subgoals (subgoal_id, goal_id, subgoal)
				VALUES (?, ?, ?)
				"""
				
				var subgoal_params = [
					subgoal_data.get("id", ""),
					goal_id,
					subgoal_data.get("subgoal", "")
				]
				
				if not SQLiteManager.execute_non_query(subgoal_query, subgoal_params):
					return false
				
				# 导入目标锚点
				if subgoal_data.has("goal_anchor"):
					for anchor_data in subgoal_data.goal_anchor:
						var anchor_query = """
						INSERT OR REPLACE INTO goal_anchors 
						(anchor_id, subgoal_id, affiliate, anchor_name, character_id, affiliate_type, anchor_init_value, anchor_goal_reached_value)
						VALUES (?, ?, ?, ?, ?, ?, ?, ?)
						"""
						
						var anchor_params = [
							anchor_data.get("id", ""),
							subgoal_data.get("id", ""),
							anchor_data.get("affiliate", ""),
							anchor_data.get("anchor_name", ""),
							anchor_data.get("character_id", ""),
							anchor_data.get("affiliate_type", ""),
							anchor_data.get("anchor_init_value", ""),
							anchor_data.get("anchor_goal_reached_value", "")
						]
						
						if not SQLiteManager.execute_non_query(anchor_query, anchor_params):
							return false
	
	return true

# 导入角色数据
static func _import_characters_data(characters_data: Array, chapter_id: String) -> bool:
	for character_data in characters_data:
		var character = CharacterModel.new(character_data)
		character.chapter_id = chapter_id
		
		# 处理base_position
		if character_data.has("basePosition"):
			var base_pos = character_data.basePosition
			character.base_position_x = base_pos.get("x", 0.0)
			character.base_position_y = base_pos.get("y", 0.0)
		
		var query = """
		INSERT OR REPLACE INTO characters 
		(character_id, chapter_id, name, type, avatar, phases, voice_profile, opening_line, intro,
		 character_tags, image_references, modules, appearance, hp, mp, texture, unit_type, is_init,
		 spawn_x, spawn_y, talk_value, action_key, is_patrol, patrol_range, patrol_range_type,
		 emoji, emoji_desc, emoji_summary, action_id, base_position_x, base_position_y, talk_topic,
		 talk_topic_emoji, arrived_target_id, still_time, patrol_timer, current_x, current_y, functions,
		 max_epochs, prompt, plugins, model_config, game_info, sprite_url, pronouns, age, background,
		 traits, tone, interests, response_emojis, response_gestures, dialogue_reference, creator,
		 creator_notes, version, module_details, entries, user_id, persona_id, control_type, client_session_id)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		"""
		
		var dict = character.to_dict()
		var params = [
			dict.character_id, dict.chapter_id, dict.name, dict.type, dict.avatar, dict.phases,
			dict.voice_profile, dict.opening_line, dict.intro, dict.character_tags, dict.image_references,
			dict.modules, dict.appearance, dict.hp, dict.mp, dict.texture, dict.unit_type, dict.is_init,
			dict.spawn_x, dict.spawn_y, dict.talk_value, dict.action_key, dict.is_patrol, dict.patrol_range,
			dict.patrol_range_type, dict.emoji, dict.emoji_desc, dict.emoji_summary, dict.action_id,
			dict.base_position_x, dict.base_position_y, dict.talk_topic, dict.talk_topic_emoji,
			dict.arrived_target_id, dict.still_time, dict.patrol_timer, dict.current_x, dict.current_y,
			dict.functions, dict.max_epochs, dict.prompt, dict.plugins, dict.model_config, dict.game_info,
			dict.sprite_url, dict.pronouns, dict.age, dict.background, dict.traits, dict.tone, dict.interests,
			dict.response_emojis, dict.response_gestures, dict.dialogue_reference, dict.creator,
			dict.creator_notes, dict.version, dict.module_details, dict.entries, dict.user_id,
			dict.persona_id, dict.control_type, dict.client_session_id
		]
		
		if not SQLiteManager.execute_non_query(query, params):
			return false
	
	return true

# 导入玩家数据
static func _import_players_data(players_data: Array, chapter_id: String) -> bool:
	for player_data in players_data:
		var player = CharacterModel.new(player_data)
		player.chapter_id = chapter_id
		player.type = "player"
		
		# 处理basePosition
		if player_data.has("basePosition"):
			var base_pos = player_data.basePosition
			player.base_position_x = base_pos.get("x", 0.0) if base_pos.get("x") != null else 0.0
			player.base_position_y = base_pos.get("y", 0.0) if base_pos.get("y") != null else 0.0
		
		# 处理spawnX和spawnY
		player.spawn_x = player_data.get("spawnX", 0.0) if player_data.get("spawnX") != null else 0.0
		player.spawn_y = player_data.get("spawnY", 0.0) if player_data.get("spawnY") != null else 0.0
		
		# 处理玩家特有字段
		player.user_id = player_data.get("userId", "")
		player.control_type = player_data.get("controlType", 0)
		player.client_session_id = player_data.get("clientSessionId", "")
		
		var query = """
		INSERT OR REPLACE INTO characters 
		(character_id, chapter_id, name, type, avatar, phases, voice_profile, opening_line, intro,
		 character_tags, image_references, modules, appearance, hp, mp, texture, unit_type, is_init,
		 spawn_x, spawn_y, talk_value, action_key, is_patrol, patrol_range, patrol_range_type,
		 emoji, emoji_desc, emoji_summary, action_id, base_position_x, base_position_y, talk_topic,
		 talk_topic_emoji, arrived_target_id, still_time, patrol_timer, current_x, current_y, functions,
		 max_epochs, prompt, plugins, model_config, game_info, sprite_url, pronouns, age, background,
		 traits, tone, interests, response_emojis, response_gestures, dialogue_reference, creator,
		 creator_notes, version, module_details, entries, user_id, persona_id, control_type, client_session_id)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		"""
		
		var dict = player.to_dict()
		var params = [
			dict.character_id, dict.chapter_id, dict.name, dict.type, dict.avatar, dict.phases,
			dict.voice_profile, dict.opening_line, dict.intro, dict.character_tags, dict.image_references,
			dict.modules, dict.appearance, dict.hp, dict.mp, dict.texture, dict.unit_type, dict.is_init,
			dict.spawn_x, dict.spawn_y, dict.talk_value, dict.action_key, dict.is_patrol, dict.patrol_range,
			dict.patrol_range_type, dict.emoji, dict.emoji_desc, dict.emoji_summary, dict.action_id,
			dict.base_position_x, dict.base_position_y, dict.talk_topic, dict.talk_topic_emoji,
			dict.arrived_target_id, dict.still_time, dict.patrol_timer, dict.current_x, dict.current_y,
			dict.functions, dict.max_epochs, dict.prompt, dict.plugins, dict.model_config, dict.game_info,
			dict.sprite_url, dict.pronouns, dict.age, dict.background, dict.traits, dict.tone, dict.interests,
			dict.response_emojis, dict.response_gestures, dict.dialogue_reference, dict.creator,
			dict.creator_notes, dict.version, dict.module_details, dict.entries, dict.user_id,
			dict.persona_id, dict.control_type, dict.client_session_id
		]
		
		if not SQLiteManager.execute_non_query(query, params):
			return false
	
	return true

# 导入角色章节信息
static func _import_character_chapter_info(character_info_data: Array, chapter_id: String) -> bool:
	for info_data in character_info_data:
		var query = """
		INSERT OR REPLACE INTO character_chapter_info (character_id, chapter_id, emotion, recent_ongoing, personal_setting)
		VALUES (?, ?, ?, ?, ?)
		"""
		
		var params = [
			info_data.get("character_id", ""),
			chapter_id,
			info_data.get("emotion", ""),
			info_data.get("recent_ongoing", ""),
			info_data.get("personal_setting", "")
		]
		
		if not SQLiteManager.execute_non_query(query, params):
			return false
	
	return true

# 导入章节参与者
static func _import_chapter_participants(participants_data: Array, chapter_id: String) -> bool:
	for participant_data in participants_data:
		var query = """
		INSERT OR REPLACE INTO chapter_participants (chapter_id, character_id, name)
		VALUES (?, ?, ?)
		"""
		
		var params = [
			chapter_id,
			participant_data.get("character_id", ""),
			participant_data.get("name", "")
		]
		
		if not SQLiteManager.execute_non_query(query, params):
			return false
	
	return true

# 导入建筑数据
static func _import_buildings_data(buildings_data: Array, chapter_id: String, game_id: String) -> bool:
	for building_data in buildings_data:
		var query = """
		INSERT OR REPLACE INTO buildings 
		(building_id, name, entity_id, user_id, map_id, category, chapter_id, game_id, appearance,
		 width, height, spawn_x, spawn_y, x, y, texture, functions, depth, interaction, is_init,
		 display_width, display_height, rotation, visible)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		"""
		
		var params = [
			building_data.get("id", ""),
			building_data.get("name", ""),
			building_data.get("entity_id", ""),
			building_data.get("user_id", ""),
			building_data.get("map_id", ""),
			building_data.get("category", ""),
			chapter_id,
			game_id,
			building_data.get("appearance", ""),
			building_data.get("width", 0),
			building_data.get("height", 0),
			building_data.get("spawn_x", 0.0),
			building_data.get("spawn_y", 0.0),
			building_data.get("x", 0.0),
			building_data.get("y", 0.0),
			building_data.get("texture", ""),
			building_data.get("functions", ""),
			building_data.get("depth", 1),
			JSON.stringify(building_data.get("interaction", [])),
			building_data.get("is_init", true),
			building_data.get("display_width", 0),
			building_data.get("display_height", 0),
			building_data.get("rotation", 0.0),
			building_data.get("visible", true)
		]
		
		if not SQLiteManager.execute_non_query(query, params):
			return false
	
	return true

# 导入道具数据
static func _import_props_data(props_data: Array, chapter_id: String, game_id: String) -> bool:
	for prop_data in props_data:
		var query = """
		INSERT OR REPLACE INTO props 
		(prop_id, game_id, chapter_id, name, type, description, image_url, properties, x, y, is_active)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		"""
		
		var params = [
			prop_data.get("id", ""),
			game_id,
			chapter_id,
			prop_data.get("name", ""),
			prop_data.get("type", ""),
			prop_data.get("description", ""),
			prop_data.get("image_url", ""),
			JSON.stringify(prop_data.get("properties", {})),
			prop_data.get("x", 0.0),
			prop_data.get("y", 0.0),
			prop_data.get("is_active", true)
		]
		
		if not SQLiteManager.execute_non_query(query, params):
			return false
	
	return true

# 导入地图数据
static func _import_map_data(map_data: Dictionary, game_id: String) -> bool:
	var map_id = map_data.get("map_id", "")
	if map_id == "":
		return true  # 没有地图数据，跳过
	
	# 保存地图文件
	if not MapLoader.save_map(map_id, map_data):
		return false
	
	# 在数据库中创建地图记录
	var query = """
	INSERT OR REPLACE INTO maps (map_id, game_id, name, map_file_path, is_active)
	VALUES (?, ?, ?, ?, ?)
	"""
	
	var params = [
		map_id,
		game_id,
		"Map " + map_id,
		MapLoader.get_map_file_path(map_id),
		true
	]
	
	return SQLiteManager.execute_non_query(query, params)

# 导入会话信息
static func _import_session_info(session_data: Dictionary) -> bool:
	var query = """
	INSERT OR REPLACE INTO sessions 
	(session_id, channel_id, game_id, chapter_id, source, last_message_id, app_id, type, status, create_time, update_time)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	"""
	
	var params = [
		session_data.get("session_id", ""),
		session_data.get("channel_id", ""),
		session_data.get("game_id", ""),
		session_data.get("chapter_id", ""),
		session_data.get("source", ""),
		session_data.get("last_message_id", ""),
		session_data.get("app_id", ""),
		session_data.get("type", 0),
		session_data.get("status", 0),
		session_data.get("create_time", ""),
		session_data.get("update_time", "")
	]
	
	return SQLiteManager.execute_non_query(query, params) 