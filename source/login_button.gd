extends Button

##Make sure the button has a $RichTextLabel and you connect the _on_mouse_entered, _on_mouse_exited, and _on_pressed signals.
##Put a reference to your credentials dictionary in the constructor call Oauth2.new(credentials_reference) in the _ready function.

const SIGN_IN_TEXT = "Sign In"
const SIGN_OUT_TEXT = "Sign Out"

@onready var rich_text_label = $RichTextLabel

var oauth_manager : Node
var signed_in : bool = false
var auth_polling_timer : Timer
var auth_polling_stop_timer : Timer

var oauth_credentials = {
	"oauth_client_id":"1089107932175-asakh8dkn92tvd1hfkpv9iea2enf4ke2.apps.googleusercontent.com",
	"oauth_client_secret":"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",
	"oauth_auth_server":"https://accounts.google.com/o/oauth2/auth",
	"oauth_token_req":"https://oauth2.googleapis.com/token",
	"oauth_token_key": Config.TOKEN_KEY,
	"oauth_redirect_uri": "http://localhost:2567"  # 桌面平台
}

var DEFAULT_HEADERS = {
	"Content-Type": "application/json",
	"Authorization": Config.AUTHORIZATION,
	"Application-ID": "rpggo-peking_duck"
}
var Httpheaders = PackedStringArray([
	"Content-Type: application/json",
	"Authorization: %s" % Config.AUTHORIZATION,
	"Application-ID: rpggo-peking_duck"
])

const THRID_URL = "https://backend-pro-qavdnvfe5a-uc.a.run.app/open/user/getByThird"

var http_request: HTTPRequest

var user_info: Variant = null

func _process(_delta) -> void:
	if signed_in:
		text = SIGN_OUT_TEXT
		global_position.x = 20
		global_position.y = 20
	else:
		text = SIGN_IN_TEXT
		global_position.x = 274
		global_position.y = 122

func _ready():
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 加入login_buttons组，用于接收服务端的用户信息更新
	add_to_group("login_buttons")
	
	# 显示当前平台信息
	print("当前平台: ", OS.get_name())
	print("桌面平台OAuth实现")
	
	user_info = await GameCatch.load_user_info()
	
	# 使用OAuth管理器，自动处理平台差异
	oauth_manager = preload("res://addons/godot_auth/tools/oauth_manager.gd").new(oauth_credentials)
	add_child(oauth_manager)
	
	if user_info != null:
		GlobalData.user_info = user_info
		signed_in = true
		return
	signed_in = false
	initOauthManager()
	


func initOauthManager() -> void:
	oauth_manager.connect("token_authorized", _on_token_authorized)
	oauth_manager.connect("token_error", _on_token_error)
	oauth_manager.connect("working", func(): rich_text_label.text= "[wave amp=50.0 freq=5.0 connected=1]...[/wave]" )
	oauth_manager.connect("logged_out", func(): rich_text_label.text= "Sign in with Google" )

func _on_pressed():
	if signed_in:
		GameCatch.clear_user_info()
		GlobalData.user_info = null
		if oauth_manager == null:
			initOauthManager()
		oauth_manager.clear_tokens()
		signed_in = false
	else:
		rich_text_label.text = "正在启动OAuth授权..."
		print("桌面平台OAuth流程：打开授权页面")
		oauth_manager.authorize()
	
func _on_token_authorized():
	var user_info_dict = oauth_manager.get_user_info_dict()
	print("OAuth授权成功，用户信息: ", user_info_dict)
	rich_text_label.text = "%s" % user_info_dict.get("name")
	rich_text_label.tooltip_text = "sign out"
	signed_in = true
	

	
	# 改进：暂存OAuth信息，不直接调用getByThird
	# 避免客户端跨域问题，改为连接服务器时由服务端处理
	var oauth_info = {
		"source": "google",
		"third_id": user_info_dict.sub,
		"origin_data": user_info_dict,
		"access_token": oauth_manager.get_access_token() if oauth_manager.has_method("get_access_token") else ""
	}
	
	# 暂存到GlobalData，等连接服务器时发送
	GlobalData.oauth_info = oauth_info
	
	# 暂时使用OAuth信息作为基础用户信息
	var temp_user_info = {
		"name": user_info_dict.get("name", ""),
		"email": user_info_dict.get("email", ""),
		"picture": user_info_dict.get("picture", ""),
		"third_id": user_info_dict.sub,
		"oauth_pending": true  # 标记为待服务端验证
	}
	
	GlobalData.user_info = temp_user_info
	user_info = temp_user_info
	GameCatch.save_user_info(temp_user_info)
	
	print("OAuth信息已暂存，等待连接服务器时同步")
	
func _on_token_error(error : String):
	rich_text_label.text = "[color=red]error! %s[/color]" % error
	signed_in = false
	
	# Web平台特殊错误处理
	if OS.has_feature("web") and "Web OAuth only works on web platform" in error:
		rich_text_label.text = "请在桌面平台使用此功能"
	elif OS.has_feature("web"):
		rich_text_label.text = "Web平台OAuth错误，请检查配置"
	pass







func _on_mouse_entered():
	if signed_in:
		rich_text_label.text = "[color=red]sign out?[/color]"



func _on_mouse_exited():
	if signed_in && user_info:
		rich_text_label.text = "%s" % user_info.get("uid")

# 服务端用户信息更新回调
func update_user_display(user_info_param: Dictionary):
	print("更新登录按钮显示，新的用户信息: ", user_info_param)
	
	if user_info_param and user_info_param.has("name"):
		rich_text_label.text = "%s" % user_info_param.get("name")
		rich_text_label.tooltip_text = "sign out"
		signed_in = true
		
		# 如果有oauth_pending标记，清除它
		if user_info_param.has("oauth_pending"):
			var updated_user_info = user_info_param.duplicate()
			updated_user_info.erase("oauth_pending")
			GlobalData.user_info = updated_user_info
			GameCatch.save_user_info(updated_user_info)
		
		print("用户信息更新完成，来自服务端验证")
	else:
		print("收到的用户信息格式错误: ", user_info_param)
