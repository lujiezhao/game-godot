class_name WorldModel
extends RefCounted

var id: int
var world_id: String
var name: String
var user_id: String
var world_view: String
var reference: String
var knowledge_details: String
var status: String = "normal"
var version: int = 1
var characters_map: Array = []
var created_at: String
var updated_at: String

func _init(data: Dictionary = {}):
	if data.has("id"):
		id = data.id
	world_id = data.get("world_id", "")
	name = data.get("name", "")
	user_id = data.get("user_id", "")
	world_view = data.get("world_view", "")
	reference = data.get("reference", "")
	knowledge_details = data.get("knowledge_details", "")
	status = data.get("status", "normal")
	version = data.get("version", 1)
	
	if data.has("characters_map"):
		if data.characters_map is String:
			characters_map = JSON.parse_string(data.characters_map) if data.characters_map != "" else []
		else:
			characters_map = data.characters_map
	
	created_at = data.get("created_at", "")
	updated_at = data.get("updated_at", "")

func to_dict() -> Dictionary:
	return {
		"id": id,
		"world_id": world_id,
		"name": name,
		"user_id": user_id,
		"world_view": world_view,
		"reference": reference,
		"knowledge_details": knowledge_details,
		"status": status,
		"version": version,
		"characters_map": JSON.stringify(characters_map),
		"created_at": created_at,
		"updated_at": updated_at
	}

func validate() -> bool:
	return world_id != "" and name != "" and user_id != "" 