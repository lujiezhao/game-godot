extends Node
class_name OAuthManager

signal token_authorized
signal token_error(error : String)
signal working
signal logged_out

var oauth_instance : Node
var environment_variables : Dictionary

func _init(vars : Dictionary = {}) -> void:
	environment_variables = vars

func _ready():
	setup_oauth()

func setup_oauth():
	# 使用桌面平台OAuth实现
	var oauth2 = preload("res://addons/godot_auth/tools/oauth.gd").new()
	oauth2.environment_variables = environment_variables
	oauth_instance = oauth2
	add_child(oauth_instance)
	
	# 连接信号
	if oauth_instance:
		oauth_instance.token_authorized.connect(_on_token_authorized)
		oauth_instance.token_error.connect(_on_token_error)
		oauth_instance.working.connect(_on_working)
		oauth_instance.logged_out.connect(_on_logged_out)

func _on_token_authorized():
	token_authorized.emit()

func _on_token_error(error: String):
	token_error.emit(error)

func _on_working():
	working.emit()

func _on_logged_out():
	logged_out.emit()

# 代理方法，将调用转发给实际的OAuth实例
func authorize():
	if oauth_instance:
		oauth_instance.authorize()

func get_auth_code():
	if oauth_instance:
		oauth_instance.get_auth_code()

func get_token_from_auth(auth_code: String):
	if oauth_instance:
		oauth_instance.get_token_from_auth(auth_code)

func refresh_tokens() -> bool:
	if oauth_instance:
		return await oauth_instance.refresh_tokens()
	return false

func validate_tokens() -> bool:
	if oauth_instance:
		return await oauth_instance.validate_tokens()
	return false

func clear_tokens():
	if oauth_instance:
		oauth_instance.clear_tokens()

func get_user_info() -> Dictionary:
	if oauth_instance:
		return await oauth_instance.get_user_info()
	return {}

# 获取token属性
func get_token() -> String:
	if oauth_instance:
		return oauth_instance.token
	return ""

func get_refresh_token() -> String:
	if oauth_instance:
		return oauth_instance.refresh_token
	return ""

func get_user_info_dict() -> Dictionary:
	if oauth_instance:
		return oauth_instance.user_info
	return {}

# 别名方法，获取access token
func get_access_token() -> String:
	return get_token()
