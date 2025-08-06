class_name CharacterAttrSynchronizer
extends MultiplayerSynchronizer

var texture_url: String = ""
var persona_name: String = ""
var persona_ready: bool = false

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.timeout.connect(_on_timeout)

func _on_timeout():
	if owner is Player and is_multiplayer_authority():
		load_persona()
	elif owner is not Player:
		persona_ready = true

func load_persona():
	if GlobalData.user_info == null:
		return
	var uid = GlobalData.user_info.uid
	if !uid:
		return
	#var headers = {
		#"payload": Request.make_payload(uid),
		#"Authorization": Config.AUTHORIZATION
	#}
	var headers = Request.DEFAULT_DEADERS
	headers.append("payload: %s" % Request.make_payload(uid))
	var persona_res = await Request._http_post(Config.PERSONA_GET_URL, "{}", headers)
	if !persona_res:
		return
	var persona_data = persona_res.data
	if !persona_data:
		return
	persona_name = persona_data.name
	var texture = persona_data.player.texture
	if texture:
		print("player texture ==> %s" % texture)
		texture_url = texture
		#remote_texture_url = texture
		#print(remote_texture_url, remote_texture)
	persona_ready = true
