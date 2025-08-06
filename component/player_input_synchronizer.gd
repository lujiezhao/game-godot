class_name PlayerInputSynchronizer
extends MultiplayerSynchronizer

var movement_vector: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var moving_target_name: String
var static_target_name: String

func _ready() -> void:
	GameEvent.set_target.connect(set_target)

func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		gater_input()

func gater_input():
	movement_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")


func _input(event: InputEvent):
	if is_multiplayer_authority():
		set_player_target_position(event)

func set_player_target_position(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			#print("is_handle==> ", event.is_handled())
			if owner is Player:
				# 获取点击的世界坐标
				var pos = owner.get_global_mouse_position()
				target_pos = pos
				print("target_position:  ", target_pos)
				
				if owner.clear_target:
					owner.clear_target()
	#get_viewport().set_input_as_handled()

func set_target(target, type):
	if !is_multiplayer_authority():
		return
	if type == "moving":
		moving_target_name = target.name
	elif type == "static":
		static_target_name = target.name
	
	target_pos = target.global_position
