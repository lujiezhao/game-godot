class_name Player
extends Character

@onready var player_input_synchronizer: PlayerInputSynchronizer = $PlayerInputSynchronizer

func _ready() -> void:
	player_input_synchronizer.set_multiplayer_authority(name.to_int())
	#set_process(is_multiplayer_authority())
	super()

func _process(delta):
	#if navigation_agent_2d.is_navigation_finished():
		#player_input_synchronizer.target_pos = DEFAUlT_TARGET_POSITION
		#self.target_position = DEFAUlT_TARGET_POSITION
	if is_multiplayer_authority():
		move_state(delta)
		sync_target()
	super(delta)

## 重写move_state方法，因为player支持键盘操作移动
func move_state(delta):
	if player_input_synchronizer.movement_vector != Vector2.ZERO:
		move_player(player_input_synchronizer.movement_vector, delta)
	else:
		if player_input_synchronizer.target_pos != target_position:
			self.target_position = player_input_synchronizer.target_pos
		if navigation_agent_2d.is_navigation_finished():
			player_input_synchronizer.target_pos = DEFAUlT_TARGET_POSITION
		super(delta)

#@rpc("authority","call_local")
func move_player(input_vector, delta):
	if animationTree != null:
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
	if is_multiplayer_authority():
		travel_animate.rpc("Run")
	velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	navigation_agent_2d.target_position = global_position
	move_and_slide()

func sync_target():
	if player_input_synchronizer.moving_target_name != moving_target_name:
		moving_target_name = player_input_synchronizer.moving_target_name
	if player_input_synchronizer.static_target_name != static_target_name:
		static_target_name = player_input_synchronizer.static_target_name
