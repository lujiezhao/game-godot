class_name CharacterModel
extends RefCounted

# 基础角色信息
var id: int
var character_id: String
var world_id: String
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
var texture: String

# 创作者配置字段（角色的基础设定）
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

var created_at: String
var updated_at: String

func _init(data: Dictionary = {}):
	if data.has("id"):
		id = data.id
	character_id = data.get("character_id", "")
	world_id = data.get("world_id", "")
	name = data.get("name", "")
	type = data.get("type", "")
	avatar = data.get("avatar", "")
	voice_profile = data.get("voice_profile", "")
	opening_line = data.get("opening_line", "")
	intro = data.get("intro", "")
	appearance = data.get("appearance", "")
	texture = data.get("texture", "")
	
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
	
	created_at = data.get("created_at", "")
	updated_at = data.get("updated_at", "")
	
	# 解析JSON字段
	_parse_json_fields(data)

func _parse_json_fields(data: Dictionary):
	if data.has("phases"):
		if data.phases is String:
			phases = JSON.parse_string(data.phases) if data.phases != "" else ["default"]
		else:
			phases = data.phases
	
	if data.has("character_tags"):
		if data.character_tags is String:
			character_tags = JSON.parse_string(data.character_tags) if data.character_tags != "" else []
		else:
			character_tags = data.character_tags
	
	if data.has("image_references"):
		if data.image_references is String:
			image_references = JSON.parse_string(data.image_references) if data.image_references != "" else []
		else:
			image_references = data.image_references
	
	if data.has("modules"):
		if data.modules is String:
			modules = JSON.parse_string(data.modules) if data.modules != "" else []
		else:
			modules = data.modules
	
	if data.has("plugins"):
		if data.plugins is String:
			plugins = JSON.parse_string(data.plugins) if data.plugins != "" else []
		else:
			plugins = data.plugins
	
	if data.has("model_config"):
		if data.model_config is String:
			model_config = JSON.parse_string(data.model_config) if data.model_config != "" else {}
		else:
			model_config = data.model_config
	
	if data.has("game_info"):
		if data.game_info is String:
			game_info = JSON.parse_string(data.game_info) if data.game_info != "" else {}
		else:
			game_info = data.game_info
	
	if data.has("traits"):
		if data.traits is String:
			traits = JSON.parse_string(data.traits) if data.traits != "" else []
		else:
			traits = data.traits
	
	if data.has("tone"):
		if data.tone is String:
			tone = JSON.parse_string(data.tone) if data.tone != "" else []
		else:
			tone = data.tone
	
	if data.has("interests"):
		if data.interests is String:
			interests = JSON.parse_string(data.interests) if data.interests != "" else []
		else:
			interests = data.interests
	
	if data.has("module_details"):
		if data.module_details is String:
			module_details = JSON.parse_string(data.module_details) if data.module_details != "" else {}
		else:
			module_details = data.module_details
	
	if data.has("entries"):
		if data.entries is String:
			entries = JSON.parse_string(data.entries) if data.entries != "" else []
		else:
			entries = data.entries

func to_dict() -> Dictionary:
	var result = {
		"id": id,
		"character_id": character_id,
		"world_id": world_id,
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
		"texture": texture,
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
		"created_at": created_at,
		"updated_at": updated_at
	}
	
	return result

func validate() -> bool:
	return character_id != "" and world_id != "" and name != "" and type != ""

func is_npc() -> bool:
	return type == "npc"

func is_player() -> bool:
	return type == "player" 
