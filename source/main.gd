extends Node2D
const BUILDING = preload("uid://0ii5drfoqisw")
const PLAYER_TSCN = preload("uid://d0dbpy4x08i7w")
var player: Character = null

@onready var buildings: Node2D = $Buildings
@onready var Players = $Characters/Players
@onready var camera_2d: Camera2D = $Camera2D
@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawnerPlayer
@onready var game_map: GameMap = $game_map

var game_id: String = GlobalData.game_id

var game_map_readyed: bool = false

func _ready() -> void:
	multiplayer_spawner.spawn_function = create_player
	peer_ready.rpc_id(1)
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer.server_disconnected.connect(server_disconnected)
	game_map.game_map_ready.connect(_on_game_map_ready)
	game_map.init_game_data.connect(_init_game_data)

func _init_game_data(game_data):
	var _buildings = game_data.buildings
	_on_game_map_init_buildings(_buildings)

func _on_game_map_init_buildings(buildings_data: Variant) -> void:
	for building in buildings_data:
		init_building(building)

func init_building(building_data) -> void:
	if building_data.is_init == false:
		return
	var building = BUILDING.instantiate() as Building
	building.name = building_data.building_id
	buildings.add_child(building, true)
	building.add_to_group("Buildings")
	building.add_to_group("Interactives")
	building.set_texture(building_data.texture)
	building.position.x = building_data.x
	building.position.y = building_data.y
	building.collision_shape_2d.shape.size.x = building_data.width
	building.collision_shape_2d.shape.size.y = building_data.height
	var _scale = float(building_data.display_width) / float(building_data.width)
	building.global_scale = Vector2(_scale, _scale)
	#printt(building_data.id, building_data.display_width, building_data.display_height)

func _on_game_map_ready() -> void:
	if game_map_readyed == false:
		game_map_readyed = true

func create_player(data):
	var new_player = PLAYER_TSCN.instantiate()
	new_player.add_to_group("Players")
	new_player.add_to_group("Interactives")
	new_player.name = str(data.client_id)
	new_player.character_name = str(data.client_id)
	
	## 跟随相机
	if multiplayer.is_server() == false and data.client_id == multiplayer.get_unique_id():
		var remote_transform_2d = RemoteTransform2D.new()
		remote_transform_2d.remote_path = "../../../../Camera2D"
		new_player.add_child(remote_transform_2d)
	
	new_player.position.x = 320
	new_player.position.y = 160
	return new_player

func remove_player(client_id):
	if client_id == 1:
		return
	var disconnected_player = Players.get_node(str(client_id))
	if disconnected_player != null:
		disconnected_player.queue_free()

@rpc("any_peer", "call_local", "reliable")
func peer_ready():
	#print("peer %s ready" % multiplayer.get_remote_sender_id())
	var client_id = multiplayer.get_remote_sender_id()
	if client_id != 1:
		multiplayer_spawner.spawn({ "client_id": client_id })
		# 客户端连接成功后，发送OAuth信息给服务端
		if GlobalData.oauth_info != null:
			print("客户端连接成功，发送OAuth信息给服务端")
			sync_oauth_to_server.rpc_id(1, GlobalData.oauth_info)

func server_disconnected():
	print("server_disconnected")
	
	# 使用简化的场景切换
	get_tree().change_scene_to_file("res://source/main_menu_simple.tscn")

# 客户端向服务端同步OAuth信息
@rpc("any_peer", "call_remote", "reliable")
func sync_oauth_to_server(oauth_info: Dictionary):
	if multiplayer.is_server():
		var client_id = multiplayer.get_remote_sender_id()
		print("服务端收到客户端 %d 的OAuth信息" % client_id)
		print("OAuth信息: ", oauth_info)
		
		# 调用getByThird获取完整用户信息
		await process_oauth_and_get_user_info(client_id, oauth_info)

# 服务端处理OAuth并获取用户信息
func process_oauth_and_get_user_info(client_id: int, oauth_info: Dictionary):
	print("服务端开始处理OAuth，客户端ID: %d" % client_id)
	
	var params = {
		"source": oauth_info.get("source", "google"),
		"third_id": oauth_info.get("third_id", ""),
		"origin_data": oauth_info.get("origin_data", {})
	}
	
	# 服务端调用getByThird接口
	var headers = [
		"Content-Type: application/json",
		"Authorization: %s" % Config.AUTHORIZATION,
		"Application-ID: rpggo-peking_duck"
	]
	
	var result = await Request._http_post(
		"https://backend-pro-qavdnvfe5a-uc.a.run.app/open/user/getByThird",
		JSON.stringify(params),
		headers
	)
	
	if result and result.has("data"):
		print("服务端获取用户信息成功: ", result.data)
		# 将用户信息同步回客户端
		sync_user_info_to_client.rpc_id(client_id, result.data)
	else:
		print("服务端获取用户信息失败: ", result)
		# 发送错误信息给客户端
		sync_user_info_error.rpc_id(client_id, "Failed to get user info from server")

# 服务端向客户端同步用户信息
@rpc("authority", "call_remote", "reliable")
func sync_user_info_to_client(user_info: Dictionary):
	print("客户端收到服务端的用户信息: ", user_info)
	
	# 更新全局用户信息
	GlobalData.user_info = user_info
	GlobalData.oauth_info = null  # 清除OAuth临时信息
	
	# 保存用户信息
	GameCatch.save_user_info(user_info)
	
	# 通知UI更新
	get_tree().call_group("login_buttons", "update_user_display", user_info)

# 服务端向客户端同步错误信息
@rpc("authority", "call_remote", "reliable")
func sync_user_info_error(error_message: String):
	print("服务端用户信息获取失败: ", error_message)
	# 可以在这里处理错误显示逻辑
