extends CharacterBody2D
class_name Character

@export var MAX_SPEED = 30
@export var ACCELERATION = 500
@export var ROLL_SPEED = 120
@export var FRICTION = 500
@onready var animationTree: AnimationTree = $AnimationTree
@onready var state_machine = $AnimationTree.get("parameters/playback")
@onready var sprite: Sprite2D = $Sprite2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var unit_name: Label = $unit_name
@onready var character_attr_synchronizer: CharacterAttrSynchronizer = $character_attr_synchronizer
@onready var texture_synchronizer: Node = $texture_synchronizer
@onready var cover_area: Area2D = $CoverArea
@onready var process_target_timer: Timer = $process_target_timer

var moving_target_name: String
var static_target_name: String
var target_node

enum {
	MOVE,
	ROLL,
	ATTACK
}

var DEFAUlT_TARGET_POSITION = Vector2.ZERO

var state = MOVE

var entered_body_size := 0

@export var target_position: Vector2 = DEFAUlT_TARGET_POSITION:
	set(value):
		if(visible == false):
			return
		if value != DEFAUlT_TARGET_POSITION and target_position != value:
			update_target_position_for_nav(value)
		target_position = value

func update_target_position_for_nav(value):
	if navigation_agent_2d == null:
		return
	if(value != DEFAUlT_TARGET_POSITION):
		navigation_agent_2d.target_position = value
	else:
		navigation_agent_2d.target_position = Vector2(0, 0)

var character_name: String = "":
	set(value):
		character_name = value
		if unit_name != null:
			unit_name.text = value

func _ready() -> void:
	unit_name.text = character_name
	
	cover_area.body_entered.connect(_on_cover_area_body_entered)
	cover_area.body_exited.connect(_on_cover_area_body_exited)
	
	velocity = Vector2.DOWN
	if animationTree != null:
		animationTree.set("parameters/Idle/blend_position", velocity)
	
	if self is Player:
		print("player ready")
		character_attr_synchronizer.set_multiplayer_authority(int(name))
	
	# 连接TextureSynchronizer信号
	if texture_synchronizer:
		texture_synchronizer.texture_changed.connect(_on_texture_changed)
	
	process_target_timer.timeout.connect(_on_process_target_timeout)

func _process(delta):
	if is_multiplayer_authority():
		use_state(delta)
		if moving_target_name != "":
			process_target_timer.start()
		else:
			process_target_timer.stop()
	synchronize_attr()

func use_state(delta):
	if visible == false:
		return
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			pass
		ATTACK:
			pass

func move_state(delta):
	move_character_for_target_position(delta)
	move_and_slide()

#@rpc("authority", "call_local")
func move_character_for_target_position(delta):
	if target_position != DEFAUlT_TARGET_POSITION:
		if not navigation_agent_2d.is_navigation_finished():
			var dirction = to_local(navigation_agent_2d.get_next_path_position()).normalized()
			velocity = velocity.move_toward(dirction * MAX_SPEED, ACCELERATION * delta)
			if animationTree != null:
				animationTree.set("parameters/Idle/blend_position", velocity)
				animationTree.set("parameters/Run/blend_position", velocity)
			if is_multiplayer_authority():
				travel_animate.rpc("Run")
		else:
			on_destination_reached()
	else:
		if is_multiplayer_authority():
			travel_animate.rpc("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

@rpc("authority", "call_local")
func travel_animate(anmationState: String) -> void:
	if animationTree != null and state_machine != null:
		state_machine.travel(anmationState)

func _on_cover_area_body_entered(_body: Node2D) -> void:
	entered_body_size += 1
	sprite.self_modulate.a = 0.5
	#print("cover enter")


func _on_cover_area_body_exited(_body: Node2D) -> void:
	entered_body_size -= 1
	if entered_body_size <= 0:
		sprite.self_modulate.a = 1
	#print("cover leave")

# TextureSynchronizer回调
func _on_texture_changed(_texture_url: String, texture: Texture2D) -> void:
	sprite.texture = texture

func synchronize_attr():
	if character_attr_synchronizer.persona_ready == true:
		visible = true
	if character_attr_synchronizer.texture_url != "":
		# 使用TextureSynchronizer设置texture URL
		if texture_synchronizer:
			texture_synchronizer.set_texture_url(character_attr_synchronizer.texture_url)
	if character_attr_synchronizer.persona_name != "":
		self.character_name = character_attr_synchronizer.persona_name

func on_destination_reached():
	if is_multiplayer_authority():
		travel_animate.rpc("Idle")
	if target_position != DEFAUlT_TARGET_POSITION:
		self.target_position = DEFAUlT_TARGET_POSITION
	
	if moving_target_name:
		print("arrived moving target")
	
	if static_target_name:
		print("arrived static target")

func clear_target():
	moving_target_name = ""
	static_target_name = ""
	target_node = null
	if self is Player and self.player_input_synchronizer:
		self.player_input_synchronizer.moving_target_name = ""
		self.player_input_synchronizer.static_target_name = ""

func _on_process_target_timeout():
	if moving_target_name == "":
		return
	if target_node.name != moving_target_name:
		var target_nodes = get_tree().get_nodes_in_group(moving_target_name)
		if target_nodes.size() <= 0:
			return
		target_node = target_nodes[0]
	if !target_node:
		return
	if target_node.globle_position != target_position:
		target_position = target_node.globle_position
