extends Camera2D

@onready var window_size = get_window().content_scale_size
@onready var game_map: GameMap = $"../game_map"

func _ready() -> void:
	game_map.set_camera_limit.connect(_on_game_map_set_camera_limit)

func _on_game_map_set_camera_limit(width: int, height: int) -> void:
	#print("window_size", width - window_size.x, "____", height - window_size.y)
	limit_left = 0
	limit_top = 0
	limit_right = width
	limit_bottom = height
