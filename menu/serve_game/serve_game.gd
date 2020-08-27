extends Node

onready var status_label := find_node("status_label") as Label

func _process(delta: float) -> void:
	status_label.text = {
		Logic.game_phase.INIT: "Game: INIT",
		Logic.game_phase.STARTED: "Game: STARTED",
		Logic.game_phase.COUNT: "INVALID..."
	}[Connection.server.state.game_phase]








