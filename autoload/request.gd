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
	var headers = PackedStringArray(DEFAULT_DEADERS)
	var _http_request = HTTPRequest.new()
	add_child(_http_request)
	var response_code = _http_request.request(url, headers, HTTPClient.METHOD_GET)
	if response_code == OK:
		var response = await _http_request.request_completed
		return JSON.parse_string(response[3].get_string_from_utf8())
	else:
		return {}

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
