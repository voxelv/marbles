extends Node

onready var status_label := find_node("status_label") as Label

var statuses := []

func _ready() -> void:
	for c in "abcd":
		statuses.append(find_node("%s_status" % c) as Label)

func _process(delta: float) -> void:
	status_label.text = {
		Logic.game_phase.INIT: "Game: INIT",
		Logic.game_phase.STARTED: "Game: STARTED",
		Logic.game_phase.COUNT: "INVALID..."
	}[Connection.server.state.game_phase]
	
	for i in range(Logic.player.COUNT):
		var found := false
		for id in Connection.server.clients.keys():
			if Connection.server.clients[id].player == i:
				found = true
		if found:
			statuses[i].text = "ONLINE"
		else:
			statuses[i].text = "OFFLINE"








