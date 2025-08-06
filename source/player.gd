extends CharacterBody2D

@export var MAX_SPEED = 60
@export var ACCELERATION = 500
@export var ROLL_SPEED = 120
@export var FRICTION = 500
@onready var animationTree: AnimationTree = $AnimationTree
@onready var state_machine = animationTree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

enum {
	MOVE,
	ROLL,
	ATTACK
}

var DEFAUlT_TARGET_POSITION = Vector2(-1, -1)

var state = MOVE

var target_position: Vector2 = DEFAUlT_TARGET_POSITION:
	set(value):
		if(visible == false):
			return
		target_position = value
		if(value != DEFAUlT_TARGET_POSITION):
			navigation_agent_2d.target_position = value
		else:
			navigation_agent_2d.target_position = Vector2(0, 0)

func _ready() -> void:
	velocity = Vector2.DOWN
	animationTree.set("parameters/Idle/blend_position", velocity)

func _physics_process(delta):
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
	var input_vector = Vector2.DOWN
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized() # Normalize the vector to ensure consistent speed in all directions
  
	if input_vector != Vector2.ZERO:
		#roll_vector = input_vector
		#swordHitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		state_machine.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		self.target_position = DEFAUlT_TARGET_POSITION
	elif target_position != DEFAUlT_TARGET_POSITION:
		if not navigation_agent_2d.is_navigation_finished():
			var dirction = to_local(navigation_agent_2d.get_next_path_position()).normalized()
			#navigation_agent_2d.set_velocity(dirction * MAX_SPEED)
			velocity = dirction * MAX_SPEED
			animationTree.set("parameters/Idle/blend_position", velocity)
			animationTree.set("parameters/Run/blend_position", velocity)
			state_machine.travel("Run")
		else:
			state_machine.travel("Idle")
			self.target_position = DEFAUlT_TARGET_POSITION
	else:
		state_machine.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	#if not navigation_agent_2d.is_navigation_finished():
		#var dirction = to_local(navigation_agent_2d.get_next_path_position()).normalized()
	move_and_slide()


func _on_cover_area_body_entered(_body: Node2D) -> void:
	sprite.self_modulate.a = 0.5
	#print("cover enter")


func _on_cover_area_body_exited(body: Node2D) -> void:
	sprite.self_modulate.a = 1
	#print("cover leave")
