extends Node

var THRID_HEADERS = [
	"Content-Type: application/json",
	"Authorization: %s" % Config.AUTHORIZATION,
	"Application-ID: rpggo-peking_duck"
]

var DEFAULT_DEADERS = [
	"Content-Type: application/json",
	"Authorization: %s" % Config.AUTHORIZATION,
]

func make_payload(uid: String = "") -> String:
	var payload := {
		"user_id": uid,
		"source": "web_game",
		"ip": "",
		"agent": ""
	}
	
	var json_string := JSON.stringify(payload)
	
	var utf8_bytes := json_string.to_utf8_buffer()
	return Marshalls.raw_to_base64(utf8_bytes)

func _http_post(url: String, request_data: String = "", headers: PackedStringArray = THRID_HEADERS):
	headers = PackedStringArray(headers)
	var _http_request = HTTPRequest.new()
	add_child(_http_request)
	var response_code = _http_request.request(url, headers, HTTPClient.METHOD_POST, request_data)
	if response_code == OK:
		var response = await _http_request.request_completed
		return JSON.parse_string(response[3].get_string_from_utf8())
	else:
		return {}

func _http_get(url: String):
	var headers = PackedStringArray([
		"Content-Type: application/json",
		"User-Agent: Godot/4.0",
		"Accept: application/json, text/plain, */*",
		"Cache-Control: no-cache"
	])
	
	var _http_request = HTTPRequest.new()
	add_child(_http_request)
	
	# 设置更宽松的超时和重试配置
	_http_request.timeout = 30.0
	_http_request.download_chunk_size = 65536
	
	print("🌐 发起HTTP GET请求: %s" % url)
	var response_code = _http_request.request(url, headers, HTTPClient.METHOD_GET)
	
	if response_code != OK:
		print("❌ HTTP请求失败, 错误代码: %d" % response_code)
		_http_request.queue_free()
		return {}
	
	var response = await _http_request.request_completed
	_http_request.queue_free()
	
	var result = response[0]  # HTTPRequest.Result
	var status_code = response[1]  # HTTP状态码
	var response_headers = response[2]  # 响应头
	var body = response[3]  # 响应体（PackedByteArray）
	
	print("📥 HTTP响应 - 结果: %d, 状态码: %d" % [result, status_code])
	
	# 检查请求结果
	if result != HTTPRequest.RESULT_SUCCESS:
		print("❌ HTTP请求结果错误: %d" % result)
		return {}
	
	# 检查HTTP状态码
	if status_code < 200 or status_code >= 300:
		print("❌ HTTP状态码错误: %d" % status_code)
		return {}
	
	# 检查响应体是否为空
	if body.size() == 0:
		print("⚠️ 响应体为空")
		return {}
	
	# 安全地转换为字符串
	var body_string = body.get_string_from_utf8()
	if body_string.is_empty():
		print("⚠️ 响应体转换为字符串后为空")
		return {}
	
	print("📄 响应体长度: %d 字符" % body_string.length())
	print("📄 响应体前100字符: %s" % body_string.substr(0, 100))
	
	# 尝试解析JSON
	var json = JSON.new()
	var parse_result = json.parse(body_string)
	
	if parse_result != OK:
		print("❌ JSON解析失败, 错误: %d" % parse_result)
		print("📄 原始响应体: %s" % body_string.substr(0, 500))
		
		# 尝试清理可能的BOM或其他字符
		var cleaned_string = body_string.strip_edges()
		if cleaned_string != body_string:
			print("🧹 尝试解析清理后的字符串...")
			parse_result = json.parse(cleaned_string)
			if parse_result == OK:
				print("✅ 清理后解析成功")
				return json.data
		
		return {}
	
	print("✅ JSON解析成功")
	return json.data

# 测试远程JSON获取的辅助函数
func test_remote_json_fetch():
	print("🧪 开始测试远程JSON获取...")
	var test_url = "https://storage.googleapis.com/rpggo-gameassets/GY3MCVANW/maps/fc5f56dc-3fd4-48f7-b8cb-f6c4c74fc9d5/map.json"
	var result = await _http_get(test_url)
	
	if result.is_empty():
		print("❌ 测试失败：无法获取远程JSON")
	else:
		print("✅ 测试成功：成功获取远程JSON")
		print("📊 JSON数据键: %s" % str(result.keys()))

func _http_request_image(url: String):
	var _headers = PackedStringArray(DEFAULT_DEADERS)
	var _http_request = HTTPRequest.new()
	add_child(_http_request)
	var response_code = _http_request.request(url)
	if response_code == OK:
		var response = await _http_request.request_completed
		var image_data = response[3]
		var content_type = _get_content_type(response[2])
		return {
			"image_data": image_data,
			"content_type": content_type,
		}
	else:
		return null

# 获取HTTP响应内容类型
func _get_content_type(headers: PackedStringArray) -> String:
	for header in headers:
		if header.to_lower().begins_with("content-type:"):
			return header.split(":")[1].strip_edges().split(";")[0]
	return "unknown"
