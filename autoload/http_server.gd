# http_server.gd
extends Node

var _server: TCPServer
var _port: int = Config.HTTP_PORT
var _thread: Thread
var _is_running: bool = true
var _route_manager: RouteManager

func _ready():
	# 初始化路由管理器
	_route_manager = RouteManager.new()
	print("🚀 HTTP Server 路由系统已初始化")
	#start_http_server()
	pass

func start_http_server():
	_server = TCPServer.new()
	if _server.listen(_port) == OK:
		print("HTTP Server listening on port ", _port)
		_thread = Thread.new()
		_thread.start(Callable(self, "_listen_thread"))
	else:
		push_error("Failed to start HTTP server on port %d" % _port)

func _listen_thread():
	while _is_running:
		# 等待连接（非阻塞）
		if _server.is_connection_available():
			var peer: StreamPeerTCP = _server.take_connection()
			if peer and peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
				call_deferred("handle_connection", peer)
		OS.delay_msec(10)  # 防止CPU占用过高

func handle_connection(peer: StreamPeerTCP):
	print("🔗 新连接建立")
	
	# 安全读取所有可用数据
	var request_data = PackedByteArray()
	
	# 使用更简单直接的读取方式
	var start_time = Time.get_ticks_msec()
	var timeout_ms = 5000  # 5秒超时
	
	# 等待数据到达
	while Time.get_ticks_msec() - start_time < timeout_ms:
		var available_bytes = peer.get_available_bytes()
		if available_bytes > 0:
			var result = peer.get_partial_data(available_bytes)
			if result[0] == OK and result[1].size() > 0:
				request_data.append_array(result[1])
				print("📥 读取到 %d 字节数据" % result[1].size())
			
			# 检查是否读取到完整的HTTP请求（以双换行结束）
			var current_string = request_data.get_string_from_utf8()
			if "\r\n\r\n" in current_string or "\n\n" in current_string:
				print("📥 HTTP请求读取完成，总长度: %d 字节" % request_data.size())
				break
		
		OS.delay_msec(10)
	
	if request_data.size() == 0:
		print("❌ 客户端未发送数据或连接超时")
		peer.disconnect_from_host()
		return
	
	# 转换为字符串（更安全的处理）
	var request_string : String
	var err = request_data.get_string_from_utf8()
	if typeof(err) == TYPE_STRING:
		request_string = err
	else:
		# 无法解析为UTF8，尝试转义或处理二进制
		var safe_string = ""
		for b in request_data:
			if b >= 32 and b <= 126:  # 可打印ASCII范围
				safe_string += char(b)
			else:
				safe_string += "\\x%02X" % b
		request_string = safe_string
		print("⚠️ 接收到非UTF8数据: ", safe_string)
	
	# 确保有数据行
	var lines = request_string.split("\n")
	if lines.size() == 0:
		print("❌ 请求格式错误")
		peer.disconnect_from_host()
		return
	
	# 解析请求行
	var request_line = lines[0].strip_edges().split(" ", false)
	if request_line.size() < 2:
		print("❌ 请求行格式错误: %s" % lines[0])
		peer.disconnect_from_host()
		return
	
	var method = request_line[0]
	var path = request_line[1]
	
	print("📋 处理请求: %s %s" % [method, path])
	
	# 处理请求并发送响应
	var response = await _handle_request(method, path, request_string)
	_send_response(peer, response)
	
	# 给客户端时间完成接收
	OS.delay_msec(500)
	
	# 清理
	peer.disconnect_from_host()
	print("🔌 连接已关闭")

# 更健壮的响应发送
func _send_response(peer: StreamPeerTCP, response: String):
	var bytes = response.to_utf8_buffer()
	var total_sent = 0
	
	print("📤 开始发送响应，总长度: %d 字节" % bytes.size())
	
	# 发送数据
	while total_sent < bytes.size():
		var remaining = bytes.size() - total_sent
		var chunk_size = min(remaining, 4096)  # 减小块大小，提高稳定性
		var chunk = bytes.slice(total_sent, total_sent + chunk_size)
		var status = peer.put_partial_data(chunk)
		
		if status[0] != OK:
			print("❌ 发送响应时出错: %s, 已发送: %d/%d 字节" % [error_string(status[0]), total_sent, bytes.size()])
			break
		
		total_sent += status[1]
		print("📤 已发送: %d/%d 字节 (当前块: %d 字节)" % [total_sent, bytes.size(), status[1]])
		
		# 如果当前块发送不完整，说明缓冲区满了，等待一下
		if status[1] < chunk_size:
			OS.delay_msec(50)
		else:
			OS.delay_msec(10)
	
	# 确保数据发送完成
	if total_sent == bytes.size():
		print("✅ 响应发送完成: %d 字节" % total_sent)
		# 强制刷新缓冲区
		OS.delay_msec(100)
	else:
		print("⚠️ 响应发送不完整: %d/%d 字节" % [total_sent, bytes.size()])
	
	# 给客户端时间处理数据
	OS.delay_msec(200)

func _handle_request(method: String, path: String, full_request: String) -> String:
	# 使用路由管理器处理请求
	if _route_manager:
		return await _route_manager.handle_request(method, path, full_request)
	else:
		# 备用处理（路由管理器未初始化）
		return _build_response(500, "Internal Server Error", "text/plain", "Route manager not initialized")

func _build_response(code: int, status: String, content_type: String, body: String) -> String:
	return "HTTP/1.1 %d %s\r\nContent-Type: %s\r\nContent-Length: %d\r\n\r\n%s" % [
		code, status, content_type, body.length(), body
	]

func _exit_tree():
	_is_running = false
	if _thread:
		_thread.wait_to_finish()
	print("HTTP server stopped")
