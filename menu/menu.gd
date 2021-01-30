extends Node

onready var local_game_button := find_node("local_game_button") as Button
onready var join_game_button := find_node("join_game_button") as Button
onready var serve_game_button := find_node("serve_game_button") as Button
onready var quit_to_desktop_button := find_node("quit_to_desktop_button") as Button

onready var join_game_game_key := find_node("join_game_game_key") as LineEdit

onready var tabs := find_node("tabs") as TabContainer
enum tab {MAIN, JOIN, SERVE, HOW_TO_PLAY}

var viewer:Node = null
var _peers := []

func _ready() -> void:
	Connection.clear_peers()
	
	var cli_args = OS.get_cmdline_args()
	if "SERVER" in cli_args:
		print("I am SERVER...")
		
		# Number of games
		var parsed_args := {}
		for arg in cli_args:
			if arg.find("=") > -1:
				var key_value = arg.split("=")
				parsed_args[key_value[0].lstrip("--")] = key_value[1]
		if "n_games" in parsed_args:
			Config.number_of_games = int(parsed_args["n_games"])
		
		Config.is_server = true
		Config.is_local = false
		_serve_game()
		
	if OS.get_name() in ["OSX", "Server", "Windows", "X11"]:
		serve_game_button.set_visible(true)
	if OS.get_name() in ["HTML5"]:
		quit_to_desktop_button.set_visible(false)
	
func loading_viewer():
	Omni.change_scene_with_loading("res://viewer/viewer.tscn")

func prompt_for_game_key():
	var is_mobile_browser := false
	if OS.has_feature('JavaScript'):
		if JavaScript.eval("""
		/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
		"""):
			is_mobile_browser = true
	if is_mobile_browser:
		join_game_game_key.text = JavaScript.eval("""
		window.prompt('Game Key')
		""", true)

func _on_local_game_button_pressed():
	Config.is_local = true
	Config.is_server = false
	
	Connection.setup()
	loading_viewer()

func _on_join_game_button_pressed() -> void:
	Config.is_local = false
	Config.is_server = false
	_set_menu(tab.JOIN)
	prompt_for_game_key()

func _set_menu(tab:int)->void:
	tabs.current_tab = tab

func _on_how_to_play_button_pressed():
	_set_menu(tab.HOW_TO_PLAY)

func _on_join_game_join_action(_arg1):
	_on_join_game_join_pressed()

func _on_join_game_join_pressed() -> void:
	Config.game_key = (find_node("join_game_game_key") as LineEdit).text
	
	Connection.setup()
	loading_viewer()

func _on_serve_game_button_pressed() -> void:
	Config.is_local = false
	Config.is_server = true
	_set_menu(tab.SERVE)

func _on_serve_game_serve_pressed()->void:
	Config.PORT = int((find_node("serve_game_port") as LineEdit).text)
	_serve_game()

func _serve_game():
	OS.set_window_title("[SERVER]")
	
	Connection.setup()
	get_tree().change_scene("res://served_games/served_games.tscn")

func _add_peers_to_root():
	for p in _peers:
		get_tree().get_root().add_child(p)

func _on_quit_button_pressed() -> void:
	_delete_viewer()
	get_tree().quit()

func _delete_viewer():
	if Connection.local_viewer != null:
		Connection.local_viewer.queue_free()

func _on_join_game_game_key_mouse_entered():
	prompt_for_game_key()
