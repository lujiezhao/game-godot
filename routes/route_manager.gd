# route_manager.gd
# HTTP路由管理器 - 负责请求分发和路由处理
class_name RouteManager
extends RefCounted

# 路由映射表
var _routes: Dictionary = {}

func _init():
	_register_routes()

# 注册所有路由
func _register_routes():
	# 注册游戏数据API
	register_route("GET", "/api/game/export", _handle_game_export)
	
	# 注册健康检查
	register_route("GET", "/health", _handle_health_check)
	
	print("✅ 路由注册完成")

# 注册单个路由
func register_route(method: String, path: String, handler: Callable):
	var route_key = method + ":" + path
	_routes[route_key] = handler
	print("📍 已注册路由: %s %s" % [method, path])

# 处理HTTP请求
func handle_request(method: String, path: String, full_request: String) -> String:
	print("🔄 处理请求: %s %s" % [method, path])
	
	# 解析查询参数
	var parsed_path = path
	var query_params = {}
	
	if "?" in path:
		var parts = path.split("?", false, 1)
		parsed_path = parts[0]
		if parts.size() > 1:
			query_params = _parse_query_params(parts[1])
	
	# 查找匹配的路由
	var route_key = method + ":" + parsed_path
	
	if route_key in _routes:
		var handler = _routes[route_key]
		# 构建请求上下文
		var request_context = {
			"method": method,
			"path": parsed_path,
			"query_params": query_params,
			"full_request": full_request
		}
		
		# 调用处理器
		var result = await handler.call(request_context)
		
		if result is Dictionary:
			return _build_json_response(200, "OK", result)
		else:
			return _build_response(200, "OK", "text/plain", str(result))
	else:
		print("❌ 未找到路由: %s" % route_key)
		return _build_response(404, "Not Found", "text/plain", "Endpoint not found")

# 解析查询参数
func _parse_query_params(query_string: String) -> Dictionary:
	var params = {}
	var pairs = query_string.split("&")
	
	for pair in pairs:
		if "=" in pair:
			var kv = pair.split("=", false, 1)
			if kv.size() == 2:
				params[kv[0]] = kv[1]
	
	return params

# 游戏数据导出处理器
func _handle_game_export(context: Dictionary) -> Dictionary:
	# 动态加载GameDataService
	var service_script = load("uid://ddd020xm4rp8d")
	return await service_script.export_game_data(context)

# 健康检查处理器
func _handle_health_check(_context: Dictionary) -> String:
	return "🟢 HTTP Server is running"

# 构建JSON响应
func _build_json_response(code: int, status: String, data: Dictionary) -> String:
	var json_body = JSON.stringify(data)
	print("📤 JSON响应长度: %d 字符" % json_body.length())
	print("📤 JSON数据完整性检查 - 最后10字符: '%s'" % json_body.substr(json_body.length() - 10))
	return _build_response(code, status, "application/json", json_body)

# 构建HTTP响应
func _build_response(code: int, status: String, content_type: String, body: String) -> String:
	# 计算正确的字节长度（UTF-8编码）
	var body_bytes = body.to_utf8_buffer()
	var content_length = body_bytes.size()
	
	var response = "HTTP/1.1 %d %s\r\n" % [code, status]
	response += "Content-Type: %s; charset=utf-8\r\n" % content_type
	response += "Content-Length: %d\r\n" % content_length
	response += "Access-Control-Allow-Origin: *\r\n"
	response += "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS\r\n"
	response += "Access-Control-Allow-Headers: Content-Type, Authorization\r\n"
	response += "Connection: close\r\n"
	response += "\r\n"
	response += body
	
	print("📋 HTTP响应头构建完成 - Content-Length: %d 字节, 实际body长度: %d 字符" % [content_length, body.length()])
	
	return response

# 获取所有注册的路由
func get_registered_routes() -> Array:
	var routes = []
	for route_key in _routes.keys():
		var parts = route_key.split(":", false, 1)
		if parts.size() == 2:
			routes.append({
				"method": parts[0],
				"path": parts[1]
			})
	return routes 
