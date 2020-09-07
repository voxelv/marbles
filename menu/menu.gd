extends Node

onready var local_game_button := find_node("local_game_button") as Button
onready var join_game_button := find_node("join_game_button") as Button
onready var serve_game_button := find_node("serve_game_button") as Button

onready var text_output := find_node("text_output") as TextEdit
onready var join_game_items := find_node("join_game_items") as Control
onready var serve_game_items := find_node("serve_game_items") as Control

var viewer:Node = null
var _peers := []

func _ready() -> void:
	var cli_args = OS.get_cmdline_args()
	if "SERVER" in cli_args:
		print("I am SERVER...")
		Config.is_server = true
		Config.is_local = false
		_serve_game()
	else:
		call_deferred("_load_viewer")

func _load_viewer():
	viewer = load("res://viewer/viewer.tscn").instance()

func _on_local_game_button_pressed():
	Config.is_local = true
	Config.is_server = false
	
	var peers = Connection.setup()
	
	if viewer != null:
		var root = get_tree().get_root()
		for c in root.get_children():
			root.remove_child(c)
		root.add_child(viewer)
		Connection.local_viewer = viewer
		for p in peers:
			viewer.add_child(p)
		Connection.server._client_connected(Connection.client.info.peer_id, null)
		queue_free()

func _on_join_game_button_pressed() -> void:
	Config.is_local = false
	Config.is_server = false
	_set_join_game(true)

func _on_join_game_join_action(_arg1):
	_on_join_game_join_pressed()

func _on_join_game_join_pressed() -> void:
	Config.URL = (find_node("join_game_server") as LineEdit).text
	Config.PORT = int((find_node("join_game_port") as LineEdit).text)
	
	var peers = Connection.setup()
	
	if viewer != null:
		var root = get_tree().get_root()
		root.add_child(viewer)
		Connection.local_viewer = viewer
		for p in peers:
			viewer.add_child(p)
		queue_free()

func _on_join_game_cancel_pressed():
	_set_join_game(false)

func _on_serve_game_button_pressed() -> void:
	Config.is_local = false
	Config.is_server = true
	_set_serve_game(true)

func _on_serve_game_serve_pressed()->void:
	Config.PORT = int((find_node("serve_game_port") as LineEdit).text)
	_serve_game()

func _serve_game():
	OS.set_window_title("[SERVER]")
	var serve_game_load = load("res://menu/serve_game/serve_game.tscn")
	
	_peers = Connection.setup()
	call_deferred("_add_peers_to_root")
	
	get_tree().change_scene_to(serve_game_load)

func _on_serve_game_cancel_pressed()->void:
	_set_serve_game(false)

func _add_peers_to_root():
	for p in _peers:
		get_tree().get_root().add_child(p)

func _set_join_game(join:bool)->void:
	join_game_items.visible = join
	local_game_button.disabled = join
	serve_game_button.disabled = join
	if join:
		(find_node("join_game_join") as Button).grab_focus()

func _set_serve_game(serve:bool)->void:
	serve_game_items.visible = serve
	join_game_button.disabled = serve
	local_game_button.disabled = serve

func _on_join_game_server_focus_entered() -> void:
	var join_game_server := find_node("join_game_server") as LineEdit
	join_game_server.select()

func _on_join_game_port_focus_entered() -> void:
	var join_game_port := find_node("join_game_port") as LineEdit
	join_game_port.select()




