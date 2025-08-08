extends Node

@export var game_id: String = ""

@export var user_info: Variant = null

# OAuth信息，用于连接服务器时同步
@export var oauth_info: Variant = null

var current_chapter_index: int = 0

var server_ip: String = ""
var server_port: int = 0
