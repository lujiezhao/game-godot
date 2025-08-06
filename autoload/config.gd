extends Node

@export var GAME_CACHE_ROOT = "user://rpggo_game_cache/"

var TOKEN_KEY = "rpggo-game-godot"

var GAME_SERVICE_HOST = "https://backend-pro-qavdnvfe5a-uc.a.run.app"

var PERSONA_GET_URL = "%s/open/player/persona/get" % GAME_SERVICE_HOST

var AUTHORIZATION = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.-a5bQVA4a4ytSWsiYhzLCgXCD-Irg98hkVzBhBPLulM"
