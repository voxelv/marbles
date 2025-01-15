extends Node

@onready var local_game_button := %local_game_button
@onready var join_game_button := %join_game_button
@onready var serve_game_button := %serve_game_button
@onready var quit_to_desktop_button := %quit_to_desktop_button
@onready var join_game_game_key := %join_game_game_key
@onready var tabs := %tabs

enum tab {MAIN, JOIN, SERVE, HOW_TO_PLAY}

var viewer:Node = null
var _peers := []

func _ready() -> void:
	Connection.clear_peers()
	
	var cli_args = OS.get_cmdline_args()
	
	var parsed_args := {}
	for arg in cli_args:
		if arg.find("=") > -1:
			var key_value = arg.split("=")
			parsed_args[key_value[0].lstrip("-")] = key_value[1]
	
	if "SERVER" in cli_args:
		print("I am SERVER...")
		
		Config.number_of_games = int(parsed_args.get("n_games", 0))
		
		Config.is_server = true
		Config.is_local = false
		_serve_game()
	else:
		print("I am CLIENT...")
		
		if "j" in parsed_args:
			client_join(parsed_args.get("j", "0"))
		elif "join" in parsed_args:
			client_join(parsed_args.get("join", "0"))
		
	if OS.get_name() in ["OSX", "Server", "Windows", "X11"]:
		serve_game_button.set_visible(true)
	if OS.get_name() in ["HTML5"]:
		quit_to_desktop_button.set_visible(false)

func client_join(game_key:String):
	Config.is_local = false
	Config.game_key = game_key
	
	Connection.setup()
	loading_viewer()
	
func loading_viewer():
	Omni.change_scene_with_loading("res://viewer/viewer.tscn")

func _on_local_game_button_pressed():
	Config.is_local = true
	Config.is_server = false
	
	Connection.setup()
	loading_viewer()

func _on_join_game_button_pressed() -> void:
	Config.is_local = false
	Config.is_server = false
	_set_menu(tab.JOIN)

func _set_menu(tab:int)->void:
	tabs.current_tab = tab

func _on_how_to_play_button_pressed():
	_set_menu(tab.HOW_TO_PLAY)

func _on_join_game_join_action(_arg1):
	_on_join_game_join_pressed()

func _on_join_game_join_pressed() -> void:
	Config.game_key = %join_game_game_key.text
	
	Connection.setup()
	loading_viewer()

func _on_serve_game_button_pressed() -> void:
	Config.is_local = false
	Config.is_server = true
	_set_menu(tab.SERVE)

func _on_serve_game_serve_pressed()->void:
	Config.PORT = %serve_game_port.text as int
	_serve_game()

func _serve_game():
	DisplayServer.window_set_title("[SERVER]")
	
	Connection.setup()
	get_tree().change_scene_to_file("res://served_games/served_games.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
