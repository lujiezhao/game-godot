extends Node

# OAuth管理器实例
var oauth_manager : Node

# OAuth配置变量
var oauth_vars = {
	"oauth_client_id": "your_client_id_here",
	"oauth_client_secret": "your_client_secret_here", 
	"oauth_auth_server": "https://accounts.google.com/oauth/authorize",
	"oauth_token_req": "https://oauth2.googleapis.com/token",
	"oauth_token_key": "your_encryption_key_here",
	"oauth_redirect_uri": "http://localhost:2567"  # 桌面平台
}

func _ready():
	# 创建OAuth管理器
	oauth_manager = preload("res://addons/godot_auth/tools/oauth_manager.gd").new(oauth_vars)
	add_child(oauth_manager)
	
	# 连接信号
	oauth_manager.token_authorized.connect(_on_token_authorized)
	oauth_manager.token_error.connect(_on_token_error)
	oauth_manager.working.connect(_on_working)
	oauth_manager.logged_out.connect(_on_logged_out)

func _on_token_authorized():
	print("OAuth授权成功！")
	print("用户信息: ", oauth_manager.get_user_info_dict())
	print("Token: ", oauth_manager.get_token())

func _on_token_error(error: String):
	print("OAuth错误: ", error)

func _on_working():
	print("OAuth正在工作...")

func _on_logged_out():
	print("用户已登出")

# 开始OAuth流程
func start_oauth():
	oauth_manager.authorize()

# 登出
func logout():
	oauth_manager.clear_tokens()

# 获取用户信息
func get_user_info():
	return oauth_manager.get_user_info_dict()

# 检查是否已登录
func is_logged_in() -> bool:
	return oauth_manager.get_token() != "" 