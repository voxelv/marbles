extends Node

const GameInfoUIPreload := preload("res://game/game_info.tscn")

onready var game_infos_container := find_node("game_infos_container") as Control

func _ready():
	pass

func _process(delta):
	if Connection.server != null:
		var games = Connection.server.get_games()
		
		for game_info_ui in game_infos_container.get_children():
			game_info_ui.set_visible(false)
		
		for i in len(games):
			var game_info_ui:GameInfoUI
			if (game_infos_container.get_child_count() - 1) < i:
				game_info_ui = GameInfoUIPreload.instance()
				game_infos_container.add_child(game_info_ui)
			else:
				game_info_ui = game_infos_container.get_child(i) as GameInfoUI
			
			var game := (games[i] as Game)
			game_info_ui.set_visible(true)
			game_info_ui.update_with_game(game)

func _on_create_game_button_pressed():
	Connection.server.create_game()

func _on_exit_button_pressed():
	# TODO Delete all games
	get_tree().change_scene("res://menu/menu.tscn")
