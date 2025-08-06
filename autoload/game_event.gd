extends Node

signal set_target(target, type)
signal peer_connected(id)

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)

func _on_peer_connected(id):
	peer_connected.emit(id)

## 通知设置移动目标
func emit_set_target(target, type = "moving"):
	set_target.emit(target, type)
