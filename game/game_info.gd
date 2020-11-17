extends Node
class_name GameInfoUI

signal delete_button_pressed

onready var status_label := find_node("status_label") as Label

var colors := []
var game : Game

func _ready() -> void:
	for c in "abcd":
		colors.append(find_node("%s_color" % c) as ColorRect)

func _process(delta: float) -> void:
#	update_with_game(game)
	pass

func update_with_game(game:Game):
	if game.game_state != null:
		status_label.text = {
			Logic.game_phase.INIT: 		"INIT",
			Logic.game_phase.STARTED: 	"STARTED",
			Logic.game_phase.COUNT: 	"INVALID..."
		}[game.game_state.game_phase]
		
		for i in range(Logic.player.COUNT):
			var found := false
			for ci in game.players.values():
				if ci.player == i:
					found = true
			if found:
				(colors[i] as ColorRect).color = Color.green
			else:
				(colors[i] as ColorRect).color = Color.red






