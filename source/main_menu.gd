extends Node2D

const MAIN = preload("uid://crq8smikrb6cf")

@onready var input_game_id: LineEdit = $UI/start/Input_game_id

@onready var server: CheckBox = $UI/start/server
@onready var client: CheckBox = $UI/start/client
@onready var ip: LineEdit = $UI/start/ip
@onready var port: LineEdit = $UI/start/port
@onready var button_enter_game: Button = $UI/start/Button_enter_game
@onready var button_import_json: Button = $UI/start/Button_import_json
@onready var game_data_file_dialog: FileDialog = $UI/start/gameDataFileDialog
@onready var start: Node2D = $UI/start

@onready var is_dedicated_server = OS.has_feature("dedicated_server")

var is_server: bool = true

func _process(_delta: float) -> void:
	start.visible = GlobalData.user_info != null

func _ready() -> void:
	# 打印网络配置信息
	NetworkConfig.print_network_info()
	
	# 同步UI状态和内部状态
	is_server = server.button_pressed
	print("初始化：is_server = %s, server.button_pressed = %s" % [is_server, server.button_pressed])
	

	
	if is_dedicated_server:
		print("====== dedicated_server =======")
		GlobalData.game_id = input_game_id.text
		create_server()
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(func (_id:int): print("peer_connected"))
	button_enter_game.pressed.connect(_on_button_button_down)
	button_import_json.pressed.connect(_on_import_button_down)
	server.toggled.connect(_on_server_toggled)
	client.toggled.connect(_on_client_toggled)


func _on_button_button_down() -> void:
	get_tree().root.set_content_scale_mode(Window.ContentScaleMode.CONTENT_SCALE_MODE_DISABLED)
	get_tree().root.content_scale_factor = 4
	
	# 实时同步UI状态，防止ButtonGroup导致的状态不一致
	var actual_is_server = server.button_pressed
	print("按钮点击时状态检查：")
	print("  is_server变量: %s" % is_server)
	print("  server.button_pressed: %s" % server.button_pressed)
	print("  client.button_pressed: %s" % client.button_pressed)
	
	# 如果状态不一致，以UI为准
	if is_server != actual_is_server:
		print("检测到状态不一致，以UI状态为准：%s -> %s" % [is_server, actual_is_server])
		is_server = actual_is_server
	
	print("最终决定：is_server = %s" % is_server)
	
	if is_server:
		GlobalData.game_id = input_game_id.text
		if GlobalData.game_id.length() <= 0:
			print("游戏ID为空，无法创建服务器")
			return
		create_server()
	else:
		create_client()


func _on_server_toggled(toggled_on: bool) -> void:
	print("_on_server_toggled called: %s (之前 is_server=%s)" % [toggled_on, is_server])
	if toggled_on:
		# 选中服务器时，自动取消客户端选择
		client.button_pressed = false
		is_server = true
		ip.visible = false
		input_game_id.visible = true
		print("切换到服务器模式")
	else:
		# 取消服务器选择时，检查是否需要自动选择客户端
		if not client.button_pressed:
			client.button_pressed = true
		is_server = false
		ip.visible = true
		input_game_id.visible = false
		print("切换到客户端模式")

func _on_client_toggled(toggled_on: bool) -> void:
	print("_on_client_toggled called: %s" % toggled_on)
	if toggled_on:
		# 选中客户端时，自动取消服务器选择
		server.button_pressed = false
		is_server = false
		ip.visible = true
		input_game_id.visible = false
		print("切换到客户端模式")
	else:
		# 取消客户端选择时，检查是否需要自动选择服务器
		if not server.button_pressed:
			server.button_pressed = true
		is_server = true
		ip.visible = false
		input_game_id.visible = true
		print("切换到服务器模式")


#create_server(port: int, max_clients: int = 32, max_channels: int = 0, in_bandwidth: int = 0, out_bandwidth: int = 0)
func create_server():
	var port_value = port.text.to_int()
	var peer = ENetMultiplayerPeer.new()
	
	print("创建ENet服务器，端口:", port_value)
	var error = peer.create_server(port_value)
	if error != OK:
		push_error("创建ENet服务器失败: %s" % error)
		return
	
	multiplayer.multiplayer_peer = peer
	get_tree().change_scene_to_packed(MAIN)
	HttpServer.start_http_server()

func create_client():
	var port_value = port.text.to_int()
	var ip_value = ip.text
	
	print("尝试连接到服务器: %s:%d" % [ip_value, port_value])
	
	# 验证连接参数
	if ip_value.is_empty() or port_value <= 0:
		push_error("无效的IP地址或端口号")
		return
	
	var peer = ENetMultiplayerPeer.new()
	print("桌面客户端：使用ENet连接")
	
	var error = peer.create_client(ip_value, port_value)
	if error != OK:
		var error_msg = "连接失败: %s" % error
		print(error_msg)
		push_error(error_msg)
		return
	
	print("客户端初始化成功，等待连接...")
	multiplayer.multiplayer_peer = peer



func _on_connected_to_server():
	print("_on_connected_to_server")
	get_tree().change_scene_to_packed(MAIN)

func _on_import_button_down():
	game_data_file_dialog.visible = true
