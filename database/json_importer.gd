class_name JSONImporter
extends RefCounted

# 从JSON文件导入完整游戏数据（支持多种格式）
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
	
	# 检测数据格式并调用相应的导入方法
	return import_data_with_auto_detection(json.data)

# 自动检测数据格式并导入
static func import_data_with_auto_detection(data: Dictionary) -> bool:
	var format_type = detect_data_format(data)
	
	print("🔍 检测到数据格式: %s" % format_type)
	
	match format_type:
		"EXPORT_FORMAT":
			return import_export_format_data(data)
		"CREATOR_FORMAT":
			return import_creator_data(data)
		"LEGACY_FORMAT":
			return import_game_data(data)
		_:
			push_error("未知的数据格式")
			return false

# 检测数据格式
static func detect_data_format(data: Dictionary) -> String:
	# 检测导出格式 (GY3MCVANW.json): 根节点有 game_info
	if data.has("game_info"):
		print("🎯 检测到导出格式: game_info 在根级别")
		return "EXPORT_FORMAT"
	
	# 检测Creator格式: 根节点有 world_id 和 games
	if data.has("world_id") and data.has("games"):
		print("🎯 检测到Creator格式: world_id + games 结构")
		return "CREATOR_FORMAT"
	
	# 检测旧的legacy格式: 同时有 world_info 和 game_info
	if data.has("world_info") and data.has("game_info"):
		print("🎯 检测到Legacy格式: world_info + game_info 结构")
		return "LEGACY_FORMAT"
	
	print("❓ 未知数据格式，尝试内容检测")
	# 进一步检测
	var keys = data.keys()
	print("🔍 数据包含的键: %s" % str(keys))
	
	return "UNKNOWN"

# 导入Creator JSON格式的数据
static func import_creator_data(data: Dictionary) -> bool:
	# 开始事务
	if not SQLiteManager.begin_transaction():
		push_error("无法开始事务")
		return false
	
	var success = true
	
	# 导入世界信息（顶层数据就是世界信息）
	success = _import_world_info(data)
	
	if not success:
		SQLiteManager.rollback_transaction()
		push_error("世界信息导入失败，已回滚")
		return false
	
	# 导入世界级别的角色数据
	if data.has("characters") and success:
		success = _import_world_characters(data.characters, data.world_id)
	
	if not success:
		SQLiteManager.rollback_transaction()
		push_error("角色数据导入失败，已回滚")
		return false
	
	# 导入游戏数据
	if data.has("games") and success:
		for game_data in data.games:
			success = _import_game_info(game_data, data.world_id)
			if not success:
				break
	
	if success:
		SQLiteManager.commit_transaction()
		print("Creator数据导入成功")
	else:
		SQLiteManager.rollback_transaction()
		push_error("游戏数据导入失败，已回滚")
	
	return success

# 导入世界信息
static func _import_world_info(world_data: Dictionary) -> bool:
	var world = WorldModel.new({
		"world_id": _safe_get_string(world_data, "world_id", ""),
		"name": _safe_get_string(world_data, "name", ""),
		"user_id": _safe_get_string(world_data, "user_id", ""),
		"world_view": _safe_get_string(world_data, "world_view", ""),
		"reference": _safe_get_string(world_data, "reference", ""),
		"knowledge_details": _safe_get_string(world_data, "knowledge_details", ""),
		"status": _safe_get_string(world_data, "status", "normal"),
		"version": _safe_get_int(world_data, "version", 1),
		"characters_map": _safe_get_array(world_data, "characters_map", []),
		"created_at": _safe_get_string(world_data, "created_at", ""),
		"updated_at": _safe_get_string(world_data, "updated_at", "")
	})
	
	# 检查是否已存在
	if WorldRepository.exists(world.world_id):
		return WorldRepository.update(world)
	else:
		return WorldRepository.create(world)

# 导入世界级别的角色数据
static func _import_world_characters(characters_data: Array, world_id: String) -> bool:
	for character_data in characters_data:
		var character = CharacterModel.new({
			"character_id": _safe_get_string(character_data, "character_id", ""),
			"world_id": world_id,
			"name": _safe_get_string(character_data, "name", ""),
			"type": _safe_get_string(character_data, "type", "npc"),
			"avatar": _safe_get_string(character_data, "avatar", ""),
			"phases": _safe_get_array(character_data, "phases", ["default"]),
			"voice_profile": _safe_get_string(character_data, "voice_profile", ""),
			"opening_line": _safe_get_string(character_data, "opening_line", ""),
			"intro": _safe_get_string(character_data, "intro", ""),
			"character_tags": _safe_get_array(character_data, "character_tags", []),
			"image_references": _safe_get_array(character_data, "image_references", []),
			"modules": _safe_get_array(character_data, "modules", []),
			"appearance": _safe_get_string(character_data, "appearance", ""),
			"texture": _safe_get_string(character_data, "texture", ""),
			"max_epochs": _safe_get_string(character_data, "max_epochs", "90"),
			"prompt": _safe_get_string(character_data, "prompt", ""),
			"plugins": _safe_get_array(character_data, "plugins", []),
			"model_config": _safe_get_dict(character_data, "model_config", {}),
			"game_info": _safe_get_dict(character_data, "game_info", {}),
			"sprite_url": _safe_get_string(character_data, "sprite_url", ""),
			"pronouns": _safe_get_string(character_data, "pronouns", ""),
			"age": _safe_get_string(character_data, "age", ""),
			"background": _safe_get_string(character_data, "background", ""),
			"traits": _safe_get_array(character_data, "traits", []),
			"tone": _safe_get_array(character_data, "tone", []),
			"interests": _safe_get_array(character_data, "interests", []),
			"response_emojis": _safe_get_bool(character_data, "response_emojis", false),
			"response_gestures": _safe_get_bool(character_data, "response_gestures", false),
			"dialogue_reference": _safe_get_string(character_data, "dialogue_reference", ""),
			"creator": _safe_get_string(character_data, "creator", ""),
			"creator_notes": _safe_get_string(character_data, "creator_notes", ""),
			"version": _safe_get_int(character_data, "version", 0),
			"module_details": _safe_get_dict(character_data, "module_details", {}),
			"entries": _safe_get_array(character_data, "entries", []),
			"user_id": _safe_get_string(character_data, "user_id", ""),
			"persona_id": _safe_get_string(character_data, "persona_id", ""),
			"created_at": _safe_get_string(character_data, "created_at", ""),
			"updated_at": _safe_get_string(character_data, "updated_at", "")
		})
		
		var query = """
		INSERT OR REPLACE INTO characters 
		(character_id, world_id, name, type, avatar, phases, voice_profile, opening_line, intro,
		 character_tags, image_references, modules, appearance, texture, max_epochs, prompt, 
		 plugins, model_config, game_info, sprite_url, pronouns, age, background, traits, tone, 
		 interests, response_emojis, response_gestures, dialogue_reference, creator, creator_notes, 
		 version, module_details, entries, user_id, persona_id, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		"""
		
		var dict = character.to_dict()
		var params = [
			dict.character_id, dict.world_id, dict.name, dict.type, dict.avatar, dict.phases,
			dict.voice_profile, dict.opening_line, dict.intro, dict.character_tags, dict.image_references,
			dict.modules, dict.appearance, dict.texture, dict.max_epochs, dict.prompt, dict.plugins,
			dict.model_config, dict.game_info, dict.sprite_url, dict.pronouns, dict.age, dict.background,
			dict.traits, dict.tone, dict.interests, dict.response_emojis, dict.response_gestures,
			dict.dialogue_reference, dict.creator, dict.creator_notes, dict.version, dict.module_details,
			dict.entries, dict.user_id, dict.persona_id, dict.created_at, dict.updated_at
		]
		
		if not SQLiteManager.execute_non_query(query, params):
			return false
	
	return true

# 导入游戏信息
static func _import_game_info(game_data: Dictionary, world_id: String) -> bool:
	var game = GameModel.new({
		"game_id": _safe_get_string(game_data, "game_id", ""),
		"name": _safe_get_string(game_data, "name", ""),
		"category": _safe_get_string(game_data, "category", ""),
		"background": _safe_get_string(game_data, "background", ""),
		"intro": _safe_get_string(game_data, "intro", ""),
		"image": _safe_get_string(game_data, "image", ""),
		"lang": _safe_get_string(game_data, "lang", ""),
		"genre": _safe_get_string(game_data, "genre", ""),
		"user_id": _safe_get_string(game_data, "user_id", ""),
		"moderation_level": _safe_get_string(game_data, "moderation_level", "G"),
		"background_musics": _safe_get_array(game_data, "background_musics", []),
		"use_shared_memory": _safe_get_bool(game_data, "use_shared_memory", false),
		"mechanics": _safe_get_string(game_data, "mechanics", ""),
		"operation_name": _safe_get_string(game_data, "operation_name", ""),
		"initialize_2d_status": _safe_get_bool(game_data, "initialize_2d_status", true),
		"moderate_type": _safe_get_string(game_data, "moderate_type", ""),
		"game_tags": _safe_get_array(game_data, "game_tags", []),
		"social_references": _safe_get_dict(game_data, "social_references", {}),
		"source_template_id": _safe_get_string(game_data, "source_template_id", ""),
		"image_style": _safe_get_string(game_data, "image_style", ""),
		"in_public_mode": _safe_get_bool(game_data, "in_public_mode", false),
		"editors": _safe_get_array(game_data, "editors", []),
		"create_source": _safe_get_string(game_data, "create_source", ""),
		"created_at": _safe_get_string(game_data, "created_at", ""),
		"updated_at": _safe_get_string(game_data, "updated_at", "")
	})
	
	var success = true
	
	# 导入游戏基本信息
	if GameRepository.exists(game.game_id):
		success = GameRepository.update(game)
	else:
		success = GameRepository.create(game)
	
	if not success:
		return false
	
	# 导入章节数据
	if game_data.has("chapters"):
		for chapter_data in game_data.chapters:
			success = _import_chapter_data(chapter_data, game.game_id, world_id)
			if not success:
				break
	
	return success

# 导入章节数据
static func _import_chapter_data(chapter_data: Dictionary, game_id: String, _world_id: String) -> bool:
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
	
	# 导入章节角色实例数据（从character_info创建）
	if chapter_data.has("character_info"):
		success = _import_chapter_character_instances_from_info(chapter_data.character_info, chapter_id)
		if not success:
			return false
	
	# 导入角色章节信息（保留原有的character_chapter_info表）
	if chapter_data.has("character_info"):
		success = _import_character_chapter_info(chapter_data.character_info, chapter_id)
		if not success:
			return false
	
	# 导入章节参与者
	if chapter_data.has("participants"):
		success = _import_chapter_participants(chapter_data.participants, chapter_id)
		if not success:
			return false
	
	return true

# 从character_info创建章节角色实例
static func _import_chapter_character_instances_from_info(character_info_data: Array, chapter_id: String) -> bool:
	for info_data in character_info_data:
		var character_id = info_data.get("character_id", "")
		if character_id == "":
			continue
		
		# 处理basePosition对象 (GY3MCVANW.json格式)
		var base_pos_x = 0.0
		var base_pos_y = 0.0
		if info_data.has("basePosition") and info_data.basePosition is Dictionary:
			base_pos_x = _safe_get_float(info_data.basePosition, "x", 0.0)
			base_pos_y = _safe_get_float(info_data.basePosition, "y", 0.0)
		
		# 处理functions字段（可能是数组或字符串）
		var functions_str = ""
		if info_data.has("functions"):
			var functions_data = info_data.get("functions")
			if functions_data is Array:
				functions_str = JSON.stringify(functions_data)
			elif functions_data is String:
				functions_str = functions_data
			else:
				functions_str = str(functions_data) if functions_data != null else ""
		
		# 创建章节角色实例，保留所有重要的位置和状态数据
		var instance = ChapterCharacterInstanceModel.new({
			"chapter_id": chapter_id,
			"character_id": character_id,
			"hp": _safe_get_int(info_data, "hp", 100),
			"mp": _safe_get_int(info_data, "mp", 100),
			"unit_type": _safe_get_string(info_data, "unitType", "NPC"),  # 使用JSON中的unitType
			"is_init": _safe_get_bool(info_data, "is_init", true),
			"spawn_x": _safe_get_float(info_data, "spawnX", 0.0),  # 保留spawnX
			"spawn_y": _safe_get_float(info_data, "spawnY", 0.0),  # 保留spawnY
			"talk_value": _safe_get_string(info_data, "talkValue", ""),
			"action_key": _safe_get_string(info_data, "actionKey", ""),
			"is_patrol": _safe_get_bool(info_data, "isPatrol", false),
			"patrol_range": _safe_get_int(info_data, "patrolRange", 60),
			"patrol_range_type": _safe_get_int(info_data, "patrolRangeType", 0),
			"emoji": _safe_get_string(info_data, "emoji", ""),
			"emoji_desc": _safe_get_string(info_data, "emojiDesc", ""),
			"emoji_summary": _safe_get_string(info_data, "emojiSummary", ""),
			"action_id": _safe_get_string(info_data, "actionId", ""),
			"base_position_x": base_pos_x,  # 使用basePosition.x
			"base_position_y": base_pos_y,  # 使用basePosition.y
			"talk_topic": _safe_get_string(info_data, "talkTopic", ""),
			"talk_topic_emoji": _safe_get_string(info_data, "talkTopicEmoji", ""),
			"arrived_target_id": _safe_get_string(info_data, "arrivedTargetId", ""),
			"still_time": _safe_get_int(info_data, "stillTime", 0),
			"patrol_timer": _safe_get_int(info_data, "patrolTimer", 30000),
			"current_x": _safe_get_float(info_data, "x", 0.0),  # 保留当前x位置
			"current_y": _safe_get_float(info_data, "y", 0.0),  # 保留当前y位置
			"functions": functions_str,  # 正确处理functions字段
			"chapter_specific_config": _safe_get_dict(info_data, "chapterSpecificConfig", {}),
			"control_type": _safe_get_int(info_data, "controlType", 0),
			"client_session_id": _safe_get_string(info_data, "clientSessionId", "")
		})
		
		print("🎭 导入角色实例: %s (x=%s, y=%s, spawn_x=%s, spawn_y=%s)" % [
			character_id, 
			str(info_data.get("x", "N/A")), 
			str(info_data.get("y", "N/A")),
			str(info_data.get("spawnX", "N/A")),
			str(info_data.get("spawnY", "N/A"))
		])
		
		var query = """
		INSERT OR REPLACE INTO chapter_character_instances 
		(chapter_id, character_id, hp, mp, unit_type, is_init, spawn_x, spawn_y, talk_value, action_key,
		 is_patrol, patrol_range, patrol_range_type, emoji, emoji_desc, emoji_summary, action_id,
		 base_position_x, base_position_y, talk_topic, talk_topic_emoji, arrived_target_id, still_time,
		 patrol_timer, current_x, current_y, functions, chapter_specific_config, control_type, client_session_id)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		"""
		
		var dict = instance.to_dict()
		
		# 确保章节特定配置是JSON字符串格式
		var chapter_config_str = "{}"
		if dict.has("chapter_specific_config") and dict.chapter_specific_config != null:
			if dict.chapter_specific_config is Dictionary:
				chapter_config_str = JSON.stringify(dict.chapter_specific_config)
			elif dict.chapter_specific_config is String:
				chapter_config_str = dict.chapter_specific_config
		
		var params = [
			dict.chapter_id, dict.character_id, dict.hp, dict.mp, dict.unit_type, dict.is_init,
			dict.spawn_x, dict.spawn_y, dict.talk_value, dict.action_key, dict.is_patrol,
			dict.patrol_range, dict.patrol_range_type, dict.emoji, dict.emoji_desc, dict.emoji_summary,
			dict.action_id, dict.base_position_x, dict.base_position_y, dict.talk_topic,
			dict.talk_topic_emoji, dict.arrived_target_id, dict.still_time, dict.patrol_timer,
			dict.current_x, dict.current_y, dict.functions, chapter_config_str,
			dict.control_type, dict.client_session_id
		]
		
		if not SQLiteManager.execute_non_query(query, params):
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
		_safe_get_string(chapter_data, "chapter_id", ""),
		game_id,
		_safe_get_string(chapter_data, "name", ""),
		_safe_get_string(chapter_data, "background", ""),
		_safe_get_string(chapter_data, "intro", ""),
		_safe_get_string(chapter_data, "image", ""),
		_safe_get_string(chapter_data, "background_audio", ""),
		_safe_get_string(chapter_data, "ending_audio", ""),
		_safe_get_string(chapter_data, "map_url", ""),
		JSON.stringify(_safe_get_array(chapter_data, "background_musics", [])),
		JSON.stringify(_safe_get_array(chapter_data, "init_dialogue", [])),
		JSON.stringify(_safe_get_array(chapter_data, "lore_list", [])),
		_safe_get_string(chapter_data, "endings", ""),
		_safe_get_bool(chapter_data, "no_goal", false),
		_safe_get_string(chapter_data, "goal_displayed", ""),
		_safe_get_bool(chapter_data, "all_trigger_fail", false)
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
			_safe_get_string(goal_data, "key", ""),
			_safe_get_string(goal_data, "value", "")
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
					_safe_get_string(subgoal_data, "id", ""),
					goal_id,
					_safe_get_string(subgoal_data, "subgoal", "")
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
							_safe_get_string(anchor_data, "id", ""),
							_safe_get_string(subgoal_data, "id", ""),
							_safe_get_string(anchor_data, "affiliate", ""),
							_safe_get_string(anchor_data, "anchor_name", ""),
							_safe_get_string(anchor_data, "character_id", ""),
							_safe_get_string(anchor_data, "affiliate_type", ""),
							_safe_get_string(anchor_data, "anchor_init_value", ""),
							_safe_get_string(anchor_data, "anchor_goal_reached_value", "")
						]
						
						if not SQLiteManager.execute_non_query(anchor_query, anchor_params):
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
			_safe_get_string(info_data, "character_id", ""),
			chapter_id,
			_safe_get_string(info_data, "emotion", ""),
			_safe_get_string(info_data, "recent_ongoing", ""),
			_safe_get_string(info_data, "personal_setting", "")
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
			_safe_get_string(participant_data, "character_id", ""),
			_safe_get_string(participant_data, "name", "")
		]
		
		if not SQLiteManager.execute_non_query(query, params):
			return false
	
	return true

# === 保留的兼容性方法（用于处理GY3MCVANW_full.json格式）===

# 导入游戏数据（兼容旧格式）
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
		success = _import_legacy_game_info(data.game_info)
	
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

# 导入旧格式的游戏信息（兼容性方法）
static func _import_legacy_game_info(game_data: Dictionary) -> bool:
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
	
	# 导入章节数据（旧格式）
	if game_data.has("chapters"):
		for chapter_data in game_data.chapters:
			success = _import_legacy_chapter_data(chapter_data, game.game_id)
			if not success:
				break
	
	return success

# 导入旧格式的章节数据
static func _import_legacy_chapter_data(chapter_data: Dictionary, game_id: String) -> bool:
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
	
	# 导入角色数据（旧格式，需要迁移到新结构）
	if chapter_data.has("characters"):
		success = _import_legacy_characters_data(chapter_data.characters, chapter_id)
		if not success:
			return false
	
	# 导入玩家数据
	if chapter_data.has("players"):
		success = _import_legacy_players_data(chapter_data.players, chapter_id)
		if not success:
			return false
	
	# 其他数据保持不变...
	if chapter_data.has("character_info"):
		success = _import_character_chapter_info(chapter_data.character_info, chapter_id)
		if not success:
			return false
	
	if chapter_data.has("participants"):
		success = _import_chapter_participants(chapter_data.participants, chapter_id)
		if not success:
			return false
	
	if chapter_data.has("buildings"):
		success = _import_buildings_data(chapter_data.buildings, chapter_id, game_id)
		if not success:
			return false
	
	if chapter_data.has("props"):
		success = _import_props_data(chapter_data.props, chapter_id, game_id)
		if not success:
			return false
	
	return true

# 导入旧格式的角色数据（需要迁移）
static func _import_legacy_characters_data(_characters_data: Array, _chapter_id: String) -> bool:
	push_warning("导入旧格式角色数据，建议使用新的Creator格式")
	
	# 这里需要将旧格式的角色数据迁移到新结构
	# 暂时跳过，建议使用新的Creator格式导入
	return true

# 导入旧格式的玩家数据
static func _import_legacy_players_data(_players_data: Array, _chapter_id: String) -> bool:
	push_warning("导入旧格式玩家数据，建议使用新的Creator格式")
	# 类似地，旧格式的玩家数据也需要迁移
	return true

# 其他保持不变的方法...
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

static func _import_map_data(map_data: Dictionary, _game_id: String) -> bool:
	var map_id = map_data.get("map_id", "")
	if map_id == "":
		return true
	
	# TODO: 实现地图数据导入
	return true

# 测试角色实例导入功能
static func test_character_instance_import():
	print("🧪 开始测试角色实例导入功能...")
	
	# 模拟GY3MCVANW.json格式的角色数据
	var test_character_data = {
		"id": "TEST_CHAR",
		"name": "测试角色",
		"hp": 150,
		"mp": 80,
		"unitType": "NPC",
		"is_init": true,
		"spawnX": 100,
		"spawnY": 200,
		"x": 120,
		"y": 180,
		"basePosition": {
			"x": 300,
			"y": 400
		},
		"talkValue": "测试对话",
		"isPatrol": true,
		"patrolRange": 80,
		"stillTime": 5000,
		"functions": ["test_function1", "test_function2"]
	}
	
	print("📝 测试数据: x=%s, y=%s, spawnX=%s, spawnY=%s" % [
		test_character_data.x, test_character_data.y,
		test_character_data.spawnX, test_character_data.spawnY
	])
	print("📝 basePosition: x=%s, y=%s" % [
		test_character_data.basePosition.x, test_character_data.basePosition.y
	])
	
	return true
	
	# TODO: 实现地图数据导入逻辑
	print("⚠️ 地图数据导入功能尚未实现")
	return true

# 导入导出格式的道具数据
static func _import_export_props_data(props_data: Array) -> bool:
	if props_data.is_empty():
		print("📦 没有道具数据需要导入")
		return true
	
	print("📦 导入 %d 个道具" % props_data.size())
	
	for prop_data in props_data:
		var prop_id = _safe_get_string(prop_data, "id", "")
		
		var prop_insert_query = """
			INSERT OR REPLACE INTO props 
			(prop_id, game_id, chapter_id, name, type, description, image_url, properties, x, y, is_active)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		"""
		
		var params = [
			prop_id,
			_safe_get_string(prop_data, "game_id", ""),
			_safe_get_string(prop_data, "chapter_id", ""),
			_safe_get_string(prop_data, "name", ""),
			_safe_get_string(prop_data, "type", ""),
			_safe_get_string(prop_data, "description", ""),
			_safe_get_string(prop_data, "image_url", ""),
			JSON.stringify(_safe_get_dict(prop_data, "properties", {})),
			_safe_get_float(prop_data, "x", 0.0),
			_safe_get_float(prop_data, "y", 0.0),
			_safe_get_bool(prop_data, "is_active", true)
		]
		
		var result = SQLiteManager.execute_non_query(prop_insert_query, params)
		if not result:
			push_error("道具插入失败: %s" % prop_id)
			return false
		
		print("📦 导入道具: %s (%s)" % [prop_data.get("name", "未知"), prop_id])
	
	return true

# 导入导出格式的会话信息
static func _import_export_session_info(session_data: Dictionary) -> bool:
	print("💬 导入会话信息")
	
	var session_id = _safe_get_string(session_data, "session_id", "")
	if session_id.is_empty():
		print("⚠️ 会话ID为空，跳过导入")
		return true
	
	var session_insert_query = """
		INSERT OR REPLACE INTO sessions 
		(session_id, channel_id, game_id, chapter_id, source, last_message_id, app_id, type, status, create_time, update_time)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	"""
	
	var params = [
		session_id,
		_safe_get_string(session_data, "channel_id", ""),
		_safe_get_string(session_data, "game_id", ""),
		_safe_get_string(session_data, "chapter_id", ""),
		_safe_get_string(session_data, "source", ""),
		_safe_get_string(session_data, "last_message_id", ""),
		_safe_get_string(session_data, "app_id", ""),
		_safe_get_int(session_data, "type", 1),
		_safe_get_int(session_data, "status", 1),
		_safe_get_string(session_data, "create_time", ""),
		_safe_get_string(session_data, "update_time", "")
	]
	
	var result = SQLiteManager.execute_non_query(session_insert_query, params)
	if not result:
		push_error("会话信息插入失败: %s" % session_id)
		return false
	
	print("💬 导入会话: %s" % session_id)
	return true

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

# === 安全数据获取辅助函数 ===

# 安全获取字符串，处理null值
static func _safe_get_string(data: Dictionary, key: String, default_value: String = "") -> String:
	var value = data.get(key, default_value)
	if value == null:
		return default_value
	return str(value)

# 安全获取数组，处理null值
static func _safe_get_array(data: Dictionary, key: String, default_value: Array = []) -> Array:
	var value = data.get(key, default_value)
	if value == null:
		return default_value
	if value is Array:
		return value
	return default_value

# 安全获取字典，处理null值
static func _safe_get_dict(data: Dictionary, key: String, default_value: Dictionary = {}) -> Dictionary:
	var value = data.get(key, default_value)
	if value == null:
		return default_value
	if value is Dictionary:
		return value
	return default_value

# 安全获取布尔值，处理null值
static func _safe_get_bool(data: Dictionary, key: String, default_value: bool = false) -> bool:
	var value = data.get(key, default_value)
	if value == null:
		return default_value
	if value is bool:
		return value
	# 尝试转换字符串
	if value is String:
		return value.to_lower() in ["true", "1", "yes"]
	return bool(value)

# 安全获取整数，处理null值
static func _safe_get_int(data: Dictionary, key: String, default_value: int = 0) -> int:
	var value = data.get(key, default_value)
	if value == null:
		return default_value
	if value is int:
		return value
	if value is String:
		return value.to_int()
	return int(value)

# 安全获取浮点数，处理null值
static func _safe_get_float(data: Dictionary, key: String, default_value: float = 0.0) -> float:
	var value = data.get(key, default_value)
	if value == null:
		return default_value
	if value is float:
		return value
	if value is String:
		return value.to_float()
	return float(value)

# ================================
# 导出格式 (GY3MCVANW.json) 导入功能
# ================================

# 导入导出格式的数据 (GY3MCVANW.json格式)
static func import_export_format_data(data: Dictionary) -> bool:
	# 开始事务
	if not SQLiteManager.begin_transaction():
		push_error("无法开始事务")
		return false
	
	var success = true
	
	print("📥 开始导入导出格式数据")
	
	# 从game_info中提取数据
	var game_info = data.get("game_info", {})
	if game_info.is_empty():
		push_error("导出格式数据中缺少game_info")
		SQLiteManager.rollback_transaction()
		return false
	
	# 导入游戏基本信息
	success = _import_export_game_info(game_info)
	
	if not success:
		SQLiteManager.rollback_transaction()
		push_error("游戏信息导入失败，已回滚")
		return false
	
	# 导入建筑数据（如果存在）
	if data.has("buildings"):
		success = _import_export_buildings_data(data.buildings)
		if not success:
			SQLiteManager.rollback_transaction()
			push_error("建筑数据导入失败，已回滚")
			return false
	
	# 导入道具数据（如果存在）
	if data.has("props"):
		success = _import_export_props_data(data.props)
		if not success:
			SQLiteManager.rollback_transaction()
			push_error("道具数据导入失败，已回滚")
			return false
	
	# 导入会话信息（如果存在）
	if data.has("session_info"):
		success = _import_export_session_info(data.session_info)
		if not success:
			SQLiteManager.rollback_transaction()
			push_error("会话信息导入失败，已回滚")
			return false
	
	if success:
		SQLiteManager.commit_transaction()
		print("✅ 导出格式数据导入成功")
	else:
		SQLiteManager.rollback_transaction()
		push_error("导出格式数据导入失败，已回滚")
	
	return success

# 导入导出格式的游戏信息
static func _import_export_game_info(game_info: Dictionary) -> bool:
	print("📋 导入游戏基本信息: %s" % game_info.get("name", "未知游戏"))
	
	# 创建游戏模型
	var game = GameModel.new({
		"game_id": _safe_get_string(game_info, "game_id", ""),
		"name": _safe_get_string(game_info, "name", ""),
		"category": _safe_get_string(game_info, "category", ""),
		"background": _safe_get_string(game_info, "background", ""),
		"intro": _safe_get_string(game_info, "intro", ""),
		"image": _safe_get_string(game_info, "image", ""),
		"lang": _safe_get_string(game_info, "lang", ""),
		"genre": _safe_get_string(game_info, "genre", ""),
		"user_id": _safe_get_string(game_info, "user_id", ""),
		"moderation_level": _safe_get_string(game_info, "moderation_level", "G"),
		"background_musics": _safe_get_array(game_info, "background_musics", []),
		"use_shared_memory": _safe_get_bool(game_info, "use_shared_memory", false)
	})
	
	var success = true
	
	# 创建或更新游戏记录
	if GameRepository.exists(game.game_id):
		print("🔄 更新现有游戏: %s" % game.game_id)
		success = GameRepository.update(game)
	else:
		print("➕ 创建新游戏: %s" % game.game_id)
		success = GameRepository.create(game)
	
	if not success:
		return false
	
	# 导入章节数据
	if game_info.has("chapters"):
		var chapters = game_info.chapters
		print("📚 导入 %d 个章节" % chapters.size())
		
		for chapter_data in chapters:
			success = _import_export_chapter_data(chapter_data, game.game_id)
			if not success:
				push_error("章节导入失败: %s" % chapter_data.get("chapter_id", "未知"))
				break
	
	return success

# 导入导出格式的章节数据
static func _import_export_chapter_data(chapter_data: Dictionary, game_id: String) -> bool:
	var chapter_id = _safe_get_string(chapter_data, "chapter_id", "")
	print("📄 导入章节: %s" % chapter_data.get("name", chapter_id))
	
	# 导入章节基本信息
	var success = _import_chapter_basic_info(chapter_data, game_id)
	if not success:
		return false
	
	# 导入目标数据
	if chapter_data.has("goals"):
		success = _import_export_goals_data(chapter_data.goals, chapter_id)
		if not success:
			return false
	
	# 导入角色数据
	if chapter_data.has("characters"):
		success = _import_export_characters_data(chapter_data.characters, chapter_id)
		if not success:
			return false
		
		# 同时导入到chapter_participants表
		success = _import_export_chapter_participants(chapter_data.characters, chapter_id)
		if not success:
			return false
	
	# 导入玩家数据
	if chapter_data.has("players"):
		success = _import_export_players_data(chapter_data.players, chapter_id)
		if not success:
			return false
	
	return true

# 导入导出格式的目标数据
static func _import_export_goals_data(goals_data: Array, chapter_id: String) -> bool:
	print("🎯 导入 %d 个目标" % goals_data.size())
	
	for goal_data in goals_data:
		var goal_key = _safe_get_string(goal_data, "key", "")
		var goal_value = _safe_get_string(goal_data, "value", "")
		
		# 插入目标
		var goal_insert_query = """
			INSERT OR REPLACE INTO goals (chapter_id, goal_key, goal_value)
			VALUES (?, ?, ?)
		"""
		
		var goal_result = SQLiteManager.execute_non_query(goal_insert_query, [chapter_id, goal_key, goal_value])
		if not goal_result:
			push_error("目标插入失败: %s" % goal_key)
			return false
		
		# 获取插入的goal_id
		var goal_id_query = "SELECT id FROM goals WHERE chapter_id = ? AND goal_key = ?"
		var goal_id_result = SQLiteManager.execute_query(goal_id_query, [chapter_id, goal_key])
		
		if goal_id_result.is_empty():
			push_error("无法获取目标ID: %s" % goal_key)
			return false
		
		var goal_id = goal_id_result[0].id
		
		# 导入子目标
		if goal_data.has("subgoals"):
			for subgoal_data in goal_data.subgoals:
				var success = _import_export_subgoal_data(subgoal_data, goal_id)
				if not success:
					return false
	
	return true

# 导入导出格式的子目标数据
static func _import_export_subgoal_data(subgoal_data: Dictionary, goal_id: int) -> bool:
	var subgoal_id = _safe_get_string(subgoal_data, "id", "")
	var subgoal_text = _safe_get_string(subgoal_data, "subgoal", "")
	
	# 插入子目标
	var subgoal_insert_query = """
		INSERT OR REPLACE INTO subgoals (subgoal_id, goal_id, subgoal)
		VALUES (?, ?, ?)
	"""
	
	var result = SQLiteManager.execute_non_query(subgoal_insert_query, [subgoal_id, goal_id, subgoal_text])
	if not result:
		push_error("子目标插入失败: %s" % subgoal_id)
		return false
	
	# 导入目标锚点
	if subgoal_data.has("goal_anchor"):
		for anchor_data in subgoal_data.goal_anchor:
			var success = _import_export_goal_anchor_data(anchor_data, subgoal_id)
			if not success:
				return false
	
	return true

# 导入导出格式的目标锚点数据
static func _import_export_goal_anchor_data(anchor_data: Dictionary, subgoal_id: String) -> bool:
	var anchor_insert_query = """
		INSERT OR REPLACE INTO goal_anchors 
		(anchor_id, subgoal_id, affiliate, anchor_name, character_id, affiliate_type, 
		 anchor_init_value, anchor_goal_reached_value)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	"""
	
	var params = [
		_safe_get_string(anchor_data, "id", ""),
		subgoal_id,
		_safe_get_string(anchor_data, "affiliate", ""),
		_safe_get_string(anchor_data, "anchor_name", ""),
		_safe_get_string(anchor_data, "character_id", ""),
		_safe_get_string(anchor_data, "affiliate_type", ""),
		_safe_get_string(anchor_data, "anchor_init_value", ""),
		_safe_get_string(anchor_data, "anchor_goal_reached_value", "")
	]
	
	return SQLiteManager.execute_non_query(anchor_insert_query, params)

# 导入导出格式的角色数据
static func _import_export_characters_data(characters_data: Array, chapter_id: String) -> bool:
	print("👥 导入 %d 个角色" % characters_data.size())
	
	for character_data in characters_data:
		var _character_id = _safe_get_string(character_data, "id", "")
		
		# 首先确保角色在characters表中存在（创建基础角色记录）
		var success = _ensure_character_exists(character_data)
		if not success:
			return false
		
		# 创建章节角色实例
		success = _import_export_character_instance(character_data, chapter_id)
		if not success:
			return false
	
	return true

# 确保角色在characters表中存在
static func _ensure_character_exists(character_data: Dictionary) -> bool:
	var character_id = _safe_get_string(character_data, "id", "")
	
	# 检查角色是否已存在
	var check_query = "SELECT COUNT(*) as count FROM characters WHERE character_id = ?"
	var check_result = SQLiteManager.execute_query(check_query, [character_id])
	
	if not check_result.is_empty() and check_result[0].count > 0:
		print("🔄 角色已存在: %s" % character_id)
		return true
	
	print("➕ 创建新角色: %s" % character_id)
	
	# 创建角色基础记录（需要一个默认的world_id）
	var character = CharacterModel.new({
		"character_id": character_id,
		"world_id": "DEFAULT_WORLD",  # 使用默认世界ID
		"name": _safe_get_string(character_data, "name", ""),
		"type": _safe_get_string(character_data, "type", "npc"),
		"avatar": _safe_get_string(character_data, "avatar", ""),
		"phases": _safe_get_array(character_data, "phases", ["default"]),
		"voice_profile": _safe_get_string(character_data, "voice_profile", ""),
		"opening_line": _safe_get_string(character_data, "opening_line", ""),
		"intro": _safe_get_string(character_data, "intro", ""),
		"character_tags": _safe_get_array(character_data, "character_tags", []),
		"image_references": _safe_get_array(character_data, "image_references", []),
		"modules": _safe_get_array(character_data, "modules", []),
		"appearance": _safe_get_string(character_data, "appearance", ""),
		"texture": _safe_get_string(character_data, "texture", "")
	})
	
	# 需要先确保默认世界存在
	_ensure_default_world_exists()
	
	# 使用SQL直接插入角色
	var query = """
	INSERT OR REPLACE INTO characters 
	(character_id, world_id, name, type, avatar, phases, voice_profile, opening_line, intro,
	 character_tags, image_references, modules, appearance, texture, max_epochs, prompt, 
	 plugins, model_config, game_info, sprite_url, pronouns, age, background, traits, tone, 
	 interests, response_emojis, response_gestures, dialogue_reference, creator, creator_notes, 
	 version, module_details, entries, user_id, persona_id, created_at, updated_at)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	"""
	
	var dict = character.to_dict()
	var params = [
		dict.character_id, dict.world_id, dict.name, dict.type, dict.avatar, dict.phases,
		dict.voice_profile, dict.opening_line, dict.intro, dict.character_tags, dict.image_references,
		dict.modules, dict.appearance, dict.texture, dict.max_epochs, dict.prompt, dict.plugins,
		dict.model_config, dict.game_info, dict.sprite_url, dict.pronouns, dict.age, dict.background,
		dict.traits, dict.tone, dict.interests, dict.response_emojis, dict.response_gestures,
		dict.dialogue_reference, dict.creator, dict.creator_notes, dict.version, dict.module_details,
		dict.entries, dict.user_id, dict.persona_id, dict.created_at, dict.updated_at
	]
	
	return SQLiteManager.execute_non_query(query, params)

# 确保默认世界存在
static func _ensure_default_world_exists() -> bool:
	var world_id = "DEFAULT_WORLD"
	
	# 检查是否已存在
	var check_query = "SELECT COUNT(*) as count FROM worlds WHERE world_id = ?"
	var check_result = SQLiteManager.execute_query(check_query, [world_id])
	
	if not check_result.is_empty() and check_result[0].count > 0:
		return true
	
	# 创建默认世界
	var _world = WorldModel.new({
		"world_id": world_id,
		"name": "默认世界",
		"user_id": "system",
		"world_view": "默认世界，用于导入的角色",
		"reference": "",
		"knowledge_details": "",
		"status": "normal",
		"version": 1,
		"characters_map": []
	})
	
	# 使用SQL直接插入世界
	var query = """
	INSERT OR REPLACE INTO worlds 
	(world_id, name, user_id, world_view, reference, knowledge_details, status, version, characters_map, created_at, updated_at)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
	"""
	
	var params = [
		world_id, "默认世界", "system", "默认世界，用于导入的角色", 
		"", "", "normal", 1, "[]"
	]
	
	return SQLiteManager.execute_non_query(query, params)

# 导入导出格式的角色实例数据
static func _import_export_character_instance(character_data: Dictionary, chapter_id: String) -> bool:
	var character_id = _safe_get_string(character_data, "id", "")
	
	var instance_insert_query = """
		INSERT OR REPLACE INTO chapter_character_instances 
		(chapter_id, character_id, hp, mp, spawn_x, spawn_y, current_x, current_y, 
		 unit_type, is_init, talk_value, action_key, is_patrol, patrol_range, emoji,
		 base_position_x, base_position_y, talk_topic, arrived_target_id, still_time,
		 patrol_timer, functions, control_type, client_session_id, chapter_specific_config)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	"""

	# 处理basePosition对象 (GY3MCVANW.json格式)
	var base_pos_x = 0.0
	var base_pos_y = 0.0
	if character_data.has("basePosition") and character_data.basePosition is Dictionary:
		base_pos_x = _safe_get_float(character_data.basePosition, "x", 0.0)
		base_pos_y = _safe_get_float(character_data.basePosition, "y", 0.0)
	
	var params = [
		chapter_id,
		character_id,
		_safe_get_int(character_data, "hp", 100),
		_safe_get_int(character_data, "mp", 100),
		_safe_get_float(character_data, "spawnX", 0.0),
		_safe_get_float(character_data, "spawnY", 0.0),
		_safe_get_float(character_data, "x", 0.0),
		_safe_get_float(character_data, "y", 0.0),
		_safe_get_string(character_data, "unitType", ""),
		_safe_get_bool(character_data, "is_init", false),
		_safe_get_string(character_data, "talkValue", ""),
		_safe_get_string(character_data, "actionKey", ""),
		_safe_get_bool(character_data, "isPatrol", false),
		_safe_get_int(character_data, "patrolRange", 0),
		_safe_get_string(character_data, "emoji", ""),
		base_pos_x,
		base_pos_y,
		_safe_get_string(character_data, "talkTopic", ""),
		_safe_get_string(character_data, "arrivedTargetId", ""),
		_safe_get_int(character_data, "stillTime", 0),
		_safe_get_int(character_data, "patrolTimer", 0),
		JSON.stringify(_safe_get_array(character_data, "functions", [])),
		_safe_get_string(character_data, "controlType", ""),
		_safe_get_string(character_data, "clientSessionId", ""),
		"{}"  # 空的章节特定配置
	]
	
	return SQLiteManager.execute_non_query(instance_insert_query, params)

# 导入导出格式的玩家数据
static func _import_export_players_data(players_data: Array, chapter_id: String) -> bool:
	print("🎮 导入 %d 个玩家" % players_data.size())
	
	for player_data in players_data:
		# 玩家数据处理方式与角色类似，但type设为'player'
		var player_data_copy = player_data.duplicate()
		player_data_copy["type"] = "player"
		
		var success = _import_export_characters_data([player_data_copy], chapter_id)
		if not success:
			return false
	
	return true

# 导入导出格式的建筑数据
static func _import_export_buildings_data(buildings_data: Array) -> bool:
	print("🏗️ 导入 %d 个建筑" % buildings_data.size())
	
	for building_data in buildings_data:
		var building_id = _safe_get_string(building_data, "id", "")
		
		var building_insert_query = """
			INSERT OR REPLACE INTO buildings 
			(building_id, name, entity_id, user_id, map_id, category, chapter_id, game_id,
			 appearance, width, height, spawn_x, spawn_y, x, y, texture, functions, depth,
			 interaction, is_init, display_width, display_height, rotation, visible)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		"""
		
		var params = [
			building_id,
			_safe_get_string(building_data, "name", ""),
			_safe_get_string(building_data, "entity_id", ""),
			_safe_get_string(building_data, "user_id", ""),
			_safe_get_string(building_data, "map_id", ""),
			_safe_get_string(building_data, "category", "building"),
			_safe_get_string(building_data, "chapter_id", ""),
			_safe_get_string(building_data, "game_id", ""),
			_safe_get_string(building_data, "appearance", ""),
			_safe_get_int(building_data, "width", 0),
			_safe_get_int(building_data, "height", 0),
			_safe_get_float(building_data, "spawn_x", -1.0),
			_safe_get_float(building_data, "spawn_y", -1.0),
			_safe_get_float(building_data, "x", 0.0),
			_safe_get_float(building_data, "y", 0.0),
			_safe_get_string(building_data, "texture", ""),
			_safe_get_string(building_data, "functions", ""),
			_safe_get_int(building_data, "depth", 1),
			JSON.stringify(_safe_get_array(building_data, "interaction", [])),
			_safe_get_bool(building_data, "is_init", true),
			_safe_get_int(building_data, "display_width", 0),
			_safe_get_int(building_data, "display_height", 0),
			_safe_get_float(building_data, "rotation", 0.0),
			_safe_get_bool(building_data, "visible", true)
		]
		
		var result = SQLiteManager.execute_non_query(building_insert_query, params)
		if not result:
			push_error("建筑插入失败: %s" % building_id)
			return false
		
		print("🏠 导入建筑: %s (%s)" % [building_data.get("name", "未知"), building_id])
	
	return true

# 导入导出格式的章节参与者数据
static func _import_export_chapter_participants(characters_data: Array, chapter_id: String) -> bool:
	print("👥 导入 %d 个章节参与者" % characters_data.size())
	
	for character_data in characters_data:
		var character_id = _safe_get_string(character_data, "id", "")
		var character_name = _safe_get_string(character_data, "name", "")
		
		if character_id.is_empty():
			print("⚠️ 角色ID为空，跳过参与者导入")
			continue
		
		var participant_insert_query = """
			INSERT OR REPLACE INTO chapter_participants 
			(chapter_id, character_id, name)
			VALUES (?, ?, ?)
		"""
		
		var params = [
			chapter_id,
			character_id,
			character_name
		]
		
		var result = SQLiteManager.execute_non_query(participant_insert_query, params)
		if not result:
			push_error("章节参与者插入失败: %s" % character_id)
			return false
		
		print("👤 导入章节参与者: %s (%s)" % [character_name, character_id])
	
	return true 
