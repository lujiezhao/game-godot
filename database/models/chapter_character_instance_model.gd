class_name ChapterCharacterInstanceModel
extends RefCounted

# 基础信息
var id: int
var chapter_id: String
var character_id: String

# 角色在该章节中的运行时状态
var hp: int = 100
var mp: int = 100
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

# 章节特定的配置覆盖
var chapter_specific_config: Dictionary = {}

# 玩家角色专用字段
var control_type: int
var client_session_id: String

var created_at: String
var updated_at: String

func _init(data: Dictionary = {}):
	if data.has("id"):
		id = data.id
	chapter_id = data.get("chapter_id", "")
	character_id = data.get("character_id", "")
	
	# 运行时状态
	hp = data.get("hp", 100)
	mp = data.get("mp", 100)
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
	
	# 玩家角色字段
	control_type = data.get("control_type", 0)
	client_session_id = data.get("client_session_id", "")
	
	created_at = data.get("created_at", "")
	updated_at = data.get("updated_at", "")
	
	# 解析JSON字段
	if data.has("chapter_specific_config"):
		if data.chapter_specific_config is String:
			chapter_specific_config = JSON.parse_string(data.chapter_specific_config) if data.chapter_specific_config != "" else {}
		else:
			chapter_specific_config = data.chapter_specific_config

func to_dict() -> Dictionary:
	return {
		"id": id,
		"chapter_id": chapter_id,
		"character_id": character_id,
		"hp": hp,
		"mp": mp,
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
		"chapter_specific_config": JSON.stringify(chapter_specific_config),
		"control_type": control_type,
		"client_session_id": client_session_id,
		"created_at": created_at,
		"updated_at": updated_at
	}

func validate() -> bool:
	return chapter_id != "" and character_id != ""

# 获取有效的基础位置
func get_base_position() -> Vector2:
	return Vector2(base_position_x, base_position_y)

# 获取当前位置
func get_current_position() -> Vector2:
	return Vector2(current_x, current_y)

# 设置当前位置
func set_current_position(pos: Vector2):
	current_x = pos.x
	current_y = pos.y

# 设置基础位置
func set_base_position(pos: Vector2):
	base_position_x = pos.x
	base_position_y = pos.y

# 获取配置值（支持章节特定覆盖）
func get_config_value(key: String, default_value = null):
	if chapter_specific_config.has(key):
		return chapter_specific_config[key]
	return default_value

# 设置章节特定配置
func set_config_override(key: String, value):
	chapter_specific_config[key] = value 