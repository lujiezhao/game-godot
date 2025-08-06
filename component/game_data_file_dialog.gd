extends FileDialog

@onready var input_game_id: LineEdit = $"../Input_game_id"

func _ready() -> void:
	file_selected.connect(game_data_selected)

## 导入游戏json数据
func game_data_selected(path: String):
	var json_as_text = FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(json_as_text)
	var game_id = data.game_info.game_id
	print(game_id)
	if !!!game_id:
		return
	var saveRes:bool = GameCatch.save_game_json(json_as_text, game_id)
	
	if input_game_id != null and saveRes == true:
		input_game_id.text = game_id
