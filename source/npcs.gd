extends Node2D

var NPC_SCENE = preload("res://source/character_npc.tscn")
@onready var current_scene = get_tree().current_scene
@onready var Npcs = current_scene.find_child("Npcs")
@onready var game_map: GameMap = $"../../game_map"


func _ready() -> void:
	game_map.init_game_data.connect(_on_game_map_init_npcs)

func _on_game_map_init_npcs(game_data: Variant) -> void:
	var npcs_data = game_data.game_info.chapters[GlobalData.current_chapter_index].characters
	if is_multiplayer_authority():
		for npc in npcs_data:
			init_npc(npc)

func init_npc(npc_data):
	#pass
	if npc_data.is_init == false:
		return
	var npc = NPC_SCENE.instantiate() as Npc
	npc.name = npc_data.id
	Npcs.add_child(npc, true)
	npc.add_to_group("Npcs")
	npc.add_to_group("Interactives")
	if npc_data.texture and npc.texture_synchronizer:
		npc.texture_synchronizer.set_texture_url(npc_data.texture)
	npc.position.x = float(npc_data.current_x)
	npc.position.y = float(npc_data.current_y)
	npc.character_name = npc_data.name
	
