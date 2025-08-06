class_name Npc
extends Character

func _ready() -> void:
	super()

func _process(delta):
	super(delta)

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		if sprite.get_rect().has_point(to_local(get_global_mouse_position())):
			print("click npc ===> %s" % name)
			GameEvent.emit_set_target(self, "moving")
			get_viewport().set_input_as_handled()
