# http_server.gd
extends Node

var _server: TCPServer
var _port: int = 9080
var _thread: Thread
var _is_running: bool = true

func _ready():
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
	# 安全读取所有可用数据
	var request_data = PackedByteArray()
	var last_size = 0
	
	# 使用超时循环读取数据
	var start_time = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_time < 5000:  # 5秒超时
		var available_bytes = peer.get_available_bytes()
		if available_bytes > 0 and available_bytes != last_size:
			var data = peer.get_partial_data(available_bytes)[1]
			if data:
				request_data.append_array(data)
				last_size = available_bytes
		elif available_bytes == 0 and request_data.size() > 0:
			break  # 没有更多数据了
		OS.delay_msec(10)
	
	if request_data.size() == 0:
		print("No data received from client")
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
		print("Received non-UTF8 data: ", safe_string)
	
	# 确保有数据行
	var lines = request_string.split("\n")
	if lines.size() == 0:
		peer.disconnect_from_host()
		return
	
	# 解析请求行
	var request_line = lines[0].split(" ", false)
	if request_line.size() < 2:
		peer.disconnect_from_host()
		return
	
	var method = request_line[0]
	var path = request_line[1]
	
	# 处理请求并发送响应
	var response = _handle_request(method, path, request_string)
	_send_response(peer, response)
	
	# 清理
	peer.disconnect_from_host()

# 更健壮的响应发送
func _send_response(peer: StreamPeerTCP, response: String):
	var bytes = response.to_utf8_buffer()
	var total_sent = 0
	
	while total_sent < bytes.size():
		var chunk = bytes.slice(total_sent)
		var status = peer.put_partial_data(chunk)
		
		if status[0] != OK:
			print("Error sending response: ", error_string(status[0]))
			break
		
		total_sent += status[1]
		OS.delay_msec(5)

func _handle_request(method: String, path: String, _full_request: String) -> String:
	# 示例API处理
	match path:
		"/get_user_info":
			if method != "GET":
				return _build_response(405, "Method Not Allowed", "text/plain", "Only GET supported")
				
			# 实际应用中这里从游戏服务器获取数据
			var user_data = {
				"id": 1001,
				"name": "JohnDoe",
				"level": 25,
				"last_login": "2023-07-29T12:34:56Z"
			}
			
			return _build_response(200, "OK", "application/json", JSON.stringify(user_data))
			
		"/health":
			return _build_response(200, "OK", "text/plain", "SERVER OK")
			
		_:
			return _build_response(404, "Not Found", "text/plain", "Endpoint not found")

func _build_response(code: int, status: String, content_type: String, body: String) -> String:
	return "HTTP/1.1 %d %s\r\nContent-Type: %s\r\nContent-Length: %d\r\n\r\n%s" % [
		code, status, content_type, body.length(), body
	]

func _exit_tree():
	_is_running = false
	if _thread and _thread.is_active and _thread.is_active():
		_thread.wait_to_finish()
	print("HTTP server stopped")
