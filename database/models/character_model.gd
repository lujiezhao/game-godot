class_name CharacterModel
extends RefCounted

var id: int
var character_id: String
var chapter_id: String
var name: String
var type: String
var avatar: String
var phases: Array = ["default"]
var voice_profile: String
var opening_line: String
var intro: String
var character_tags: Array = []
var image_references: Array = []
var modules: Array = []
var appearance: String
var hp: int = 100
var mp: int = 100
var texture: String
var unit_type: String
var is_init: bool = true
var spawn_x: float
var spawn_y: float
var talk_value: String
var action_key: String
var is_patrol: bool = false
var patrol_range: int = 60
var patrol_range_type: int = 0
var emoji: String
var emoji_desc: String
var emoji_summary: String
var action_id: String
var base_position_x: float
var base_position_y: float
var talk_topic: String
var talk_topic_emoji: String
var arrived_target_id: String
var still_time: int = 0
var patrol_timer: int = 30000
var current_x: float
var current_y: float
var functions: String

# 创作者配置字段
var max_epochs: String = "90"
var prompt: String
var plugins: Array = []
var model_config: Dictionary = {}
var game_info: Dictionary = {}
var sprite_url: String
var pronouns: String
var age: String
var background: String
var traits: Array = []
var tone: Array = []
var interests: Array = []
var response_emojis: bool = false
var response_gestures: bool = false
var dialogue_reference: String
var creator: String
var creator_notes: String
var version: int = 0
var module_details: Dictionary = {}
var entries: Array = []

# 玩家角色专用字段
var user_id: String
var persona_id: String
var control_type: int
var client_session_id: String

var created_at: String
var updated_at: String

func _init(data: Dictionary = {}):
	if data.has("id"):
		id = data.id
	character_id = data.get("character_id", "")
	chapter_id = data.get("chapter_id", "")
	name = data.get("name", "")
	type = data.get("type", "")
	avatar = data.get("avatar", "")
	voice_profile = data.get("voice_profile", "")
	opening_line = data.get("opening_line", "")
	intro = data.get("intro", "")
	appearance = data.get("appearance", "")
	hp = data.get("hp", 100)
	mp = data.get("mp", 100)
	texture = data.get("texture", "")
	unit_type = data.get("unit_type", "")
	is_init = data.get("is_init", true)
	spawn_x = data.get("spawn_x", 0.0)
	spawn_y = data.get("spawn_y", 0.0)
	talk_value = data.get("talk_value", "")
	action_key = data.get("action_key", "")
	is_patrol = data.get("is_patrol", false)
	patrol_range = data.get("patrol_range", 60)
	patrol_range_type = data.get("patrol_range_type", 0)
	emoji = data.get("emoji", "")
	emoji_desc = data.get("emoji_desc", "")
	emoji_summary = data.get("emoji_summary", "")
	action_id = data.get("action_id", "")
	base_position_x = data.get("base_position_x", 0.0)
	base_position_y = data.get("base_position_y", 0.0)
	talk_topic = data.get("talk_topic", "")
	talk_topic_emoji = data.get("talk_topic_emoji", "")
	arrived_target_id = data.get("arrived_target_id", "")
	still_time = data.get("still_time", 0)
	patrol_timer = data.get("patrol_timer", 30000)
	current_x = data.get("current_x", 0.0)
	current_y = data.get("current_y", 0.0)
	functions = data.get("functions", "")
	
	# 创作者配置
	max_epochs = data.get("max_epochs", "90")
	prompt = data.get("prompt", "")
	sprite_url = data.get("sprite_url", "")
	pronouns = data.get("pronouns", "")
	age = data.get("age", "")
	background = data.get("background", "")
	response_emojis = data.get("response_emojis", false)
	response_gestures = data.get("response_gestures", false)
	dialogue_reference = data.get("dialogue_reference", "")
	creator = data.get("creator", "")
	creator_notes = data.get("creator_notes", "")
	version = data.get("version", 0)
	
	# 玩家角色字段
	user_id = data.get("user_id", "")
	persona_id = data.get("persona_id", "")
	control_type = data.get("control_type", 0)
	client_session_id = data.get("client_session_id", "")
	
	created_at = data.get("created_at", "")
	updated_at = data.get("updated_at", "")
	
	# 处理JSON字段
	_parse_json_fields(data)

func _parse_json_fields(data: Dictionary):
	var json_fields = [
		"phases", "character_tags", "image_references", "modules",
		"plugins", "model_config", "game_info", "traits", "tone",
		"interests", "module_details", "entries"
	]
	
	for field in json_fields:
		if data.has(field):
			if data[field] is String and data[field] != "":
				set(field, JSON.parse_string(data[field]))
			elif data[field] != null:
				set(field, data[field])

func to_dict() -> Dictionary:
	var result = {
		"id": id,
		"character_id": character_id,
		"chapter_id": chapter_id,
		"name": name,
		"type": type,
		"avatar": avatar,
		"phases": JSON.stringify(phases),
		"voice_profile": voice_profile,
		"opening_line": opening_line,
		"intro": intro,
		"character_tags": JSON.stringify(character_tags),
		"image_references": JSON.stringify(image_references),
		"modules": JSON.stringify(modules),
		"appearance": appearance,
		"hp": hp,
		"mp": mp,
		"texture": texture,
		"unit_type": unit_type,
		"is_init": is_init,
		"spawn_x": spawn_x,
		"spawn_y": spawn_y,
		"talk_value": talk_value,
		"action_key": action_key,
		"is_patrol": is_patrol,
		"patrol_range": patrol_range,
		"patrol_range_type": patrol_range_type,
		"emoji": emoji,
		"emoji_desc": emoji_desc,
		"emoji_summary": emoji_summary,
		"action_id": action_id,
		"base_position_x": base_position_x,
		"base_position_y": base_position_y,
		"talk_topic": talk_topic,
		"talk_topic_emoji": talk_topic_emoji,
		"arrived_target_id": arrived_target_id,
		"still_time": still_time,
		"patrol_timer": patrol_timer,
		"current_x": current_x,
		"current_y": current_y,
		"functions": functions,
		"max_epochs": max_epochs,
		"prompt": prompt,
		"plugins": JSON.stringify(plugins),
		"model_config": JSON.stringify(model_config),
		"game_info": JSON.stringify(game_info),
		"sprite_url": sprite_url,
		"pronouns": pronouns,
		"age": age,
		"background": background,
		"traits": JSON.stringify(traits),
		"tone": JSON.stringify(tone),
		"interests": JSON.stringify(interests),
		"response_emojis": response_emojis,
		"response_gestures": response_gestures,
		"dialogue_reference": dialogue_reference,
		"creator": creator,
		"creator_notes": creator_notes,
		"version": version,
		"module_details": JSON.stringify(module_details),
		"entries": JSON.stringify(entries),
		"user_id": user_id,
		"persona_id": persona_id,
		"control_type": control_type,
		"client_session_id": client_session_id,
		"created_at": created_at,
		"updated_at": updated_at
	}
	
	return result

func validate() -> bool:
	return character_id != "" and name != "" and type != "" and chapter_id != ""

func is_npc() -> bool:
	return type == "npc"

func is_player() -> bool:
	return type == "player" 