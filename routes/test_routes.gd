# test_routes.gd
# 路由系统和游戏数据服务测试脚本
extends Node

func _ready():
	print("🧪 开始测试路由系统...")
	test_route_system()
	test_game_data_service()
	_on_ready()

func test_route_system():
	print("\n=== 测试路由管理器 ===")
	
	# 创建路由管理器
	var route_manager = RouteManager.new()
	
	# 测试健康检查路由
	print("📍 测试健康检查路由...")
	var health_context = {
		"method": "GET",
		"path": "/health",
		"query_params": {},
		"full_request": ""
	}
	var health_response = route_manager.handle_request("GET", "/health", "")
	print("健康检查响应长度: %d" % health_response.length())
	
	# 测试游戏数据导出路由（无参数）
	print("📍 测试游戏数据导出路由（无参数）...")
	var export_context_no_param = {
		"method": "GET",
		"path": "/api/game/export",
		"query_params": {},
		"full_request": ""
	}
	var export_response_no_param = route_manager.handle_request("GET", "/api/game/export", "")
	print("无参数导出响应长度: %d" % export_response_no_param.length())
	
	# 测试游戏数据导出路由（有参数）
	print("📍 测试游戏数据导出路由（有参数）...")
	var export_response_with_param = route_manager.handle_request("GET", "/api/game/export?game_id=GY3MCVANW", "")
	print("有参数导出响应长度: %d" % export_response_with_param.length())
	
	# 测试不存在的路由
	print("📍 测试不存在的路由...")
	var not_found_response = route_manager.handle_request("GET", "/api/nonexistent", "")
	print("404响应长度: %d" % not_found_response.length())
	
	# 显示所有注册的路由
	print("📋 已注册的路由:")
	var registered_routes = route_manager.get_registered_routes()
	for route in registered_routes:
		print("  %s %s" % [route.method, route.path])

func test_game_data_service():
	print("\n=== 测试游戏数据服务 ===")
	
	# 测试导出不存在的游戏
	print("📍 测试导出不存在的游戏...")
	var context_invalid = {
		"method": "GET",
		"path": "/api/game/export",
		"query_params": {"game_id": "INVALID_ID"},
		"full_request": ""
	}
	
	var service_script = load("res://routes/services/game_data_service.gd")
	var result_invalid = service_script.export_game_data(context_invalid)
	print("无效游戏ID结果: %s" % result_invalid)
	
	# 测试导出存在的游戏（如果数据库中有数据）
	print("📍 测试导出存在的游戏...")
	var context_valid = {
		"method": "GET",
		"path": "/api/game/export",
		"query_params": {"game_id": "GY3MCVANW"},
		"full_request": ""
	}
	
	var result_valid = service_script.export_game_data(context_valid)
	print("有效游戏ID结果类型: %s" % typeof(result_valid))
	
	if result_valid.has("error"):
		print("⚠️ 警告: %s" % result_valid.error)
	else:
		print("✅ 成功导出游戏数据")
		if result_valid.has("game_info"):
			var game_info = result_valid.game_info
			print("游戏名称: %s" % game_info.get("name", "未知"))
			print("游戏ID: %s" % game_info.get("game_id", "未知"))
			print("章节数量: %d" % game_info.get("chapters", []).size())

func start_http_server_test():
	print("\n=== 启动HTTP服务器测试 ===")
	
	# 获取HttpServer实例并启动
	var http_server = get_node("/root/HttpServer")
	if http_server:
		print("📡 启动HTTP服务器...")
		http_server.start_http_server()
		print("✅ HTTP服务器已启动，可以通过以下URL测试:")
		print("  健康检查: http://localhost:9080/health")
		print("  游戏数据导出: http://localhost:9080/api/game/export?game_id=GY3MCVANW")
	else:
		print("❌ 未找到HttpServer autoload节点")

# 可以通过调用这个函数来启动HTTP服务器
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_H:  # 按H键启动HTTP服务器
			start_http_server_test()
		elif event.keycode == KEY_T:  # 按T键重新运行测试
			test_route_system()
			test_game_data_service()

func _on_ready():
	print("\n💡 提示:")
	print("  按 H 键启动HTTP服务器")
	print("  按 T 键重新运行路由测试")
	print("  启动服务器后可以在浏览器中访问:")
	print("    http://localhost:9080/health")
	print("    http://localhost:9080/api/game/export?game_id=GY3MCVANW") 