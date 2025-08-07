class_name GameModel
extends RefCounted

var id: int
var game_id: String
var name: String
var category: String
var background: String
var intro: String
var image: String
var lang: String
var genre: String
var user_id: String
var moderation_level: String
var background_musics: Array = []
var use_shared_memory: bool = false
var mechanics: String
var operation_name: String
var initialize_2d_status: bool = false
var moderate_type: String
var game_tags: Array = []
var social_references: Dictionary = {}
var source_template_id: String
var image_style: String
var in_public_mode: bool = false
var editors: Array = []
var create_source: String
var created_at: String
var updated_at: String

func _init(data: Dictionary = {}):
	if data.has("id"):
		id = data.id
	game_id = data.get("game_id", "")
	name = data.get("name", "")
	category = data.get("category", "")
	background = data.get("background", "")
	intro = data.get("intro", "")
	image = data.get("image", "")
	lang = data.get("lang", "")
	genre = data.get("genre", "")
	user_id = data.get("user_id", "")
	moderation_level = data.get("moderation_level", "")
	use_shared_memory = data.get("use_shared_memory", false)
	mechanics = data.get("mechanics", "")
	operation_name = data.get("operation_name", "")
	initialize_2d_status = data.get("initialize_2d_status", false)
	moderate_type = data.get("moderate_type", "")
	source_template_id = data.get("source_template_id", "")
	image_style = data.get("image_style", "")
	in_public_mode = data.get("in_public_mode", false)
	create_source = data.get("create_source", "")
	created_at = data.get("created_at", "")
	updated_at = data.get("updated_at", "")
	
	# 处理JSON字段
	if data.has("background_musics"):
		if data.background_musics is String:
			background_musics = JSON.parse_string(data.background_musics) if data.background_musics != "" else []
		else:
			background_musics = data.background_musics if data.background_musics != null else []
	
	if data.has("game_tags"):
		if data.game_tags is String:
			game_tags = JSON.parse_string(data.game_tags) if data.game_tags != "" else []
		else:
			game_tags = data.game_tags if data.game_tags != null else []
	
	if data.has("social_references"):
		if data.social_references is String:
			social_references = JSON.parse_string(data.social_references) if data.social_references != "" else {}
		else:
			social_references = data.social_references if data.social_references != null else {}
	
	if data.has("editors"):
		if data.editors is String:
			editors = JSON.parse_string(data.editors) if data.editors != "" else []
		else:
			editors = data.editors if data.editors != null else []

func to_dict() -> Dictionary:
	return {
		"id": id,
		"game_id": game_id,
		"name": name,
		"category": category,
		"background": background,
		"intro": intro,
		"image": image,
		"lang": lang,
		"genre": genre,
		"user_id": user_id,
		"moderation_level": moderation_level,
		"background_musics": JSON.stringify(background_musics) if background_musics.size() > 0 else null,
		"use_shared_memory": use_shared_memory,
		"mechanics": mechanics,
		"operation_name": operation_name,
		"initialize_2d_status": initialize_2d_status,
		"moderate_type": moderate_type,
		"game_tags": JSON.stringify(game_tags),
		"social_references": JSON.stringify(social_references),
		"source_template_id": source_template_id,
		"image_style": image_style,
		"in_public_mode": in_public_mode,
		"editors": JSON.stringify(editors),
		"create_source": create_source,
		"created_at": created_at,
		"updated_at": updated_at
	}

func validate() -> bool:
	return game_id != "" and name != "" and user_id != "" 