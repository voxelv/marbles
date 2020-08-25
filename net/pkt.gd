extends Node

enum type {NONE, CMD, SET_CLIENTINFO, GAME_STATE, PLAYER_ROLL_REQUEST, PLAYER_PASS_REQUEST, PLAYER_MOVE_REQUEST}

enum cmd {NONE, PRINT_TEXT}

func fmt_cmd_print_text()->Dictionary:
	return {'type': type.CMD, 'cmd': cmd.PRINT_TEXT}

func fmt_set_clientinfo(info:ClientInfo):
	return {'type': type.SET_CLIENTINFO, 'player': info.player, 'peer_id': info.peer_id, 'display_name': info.display_name}

func fmt_player_roll_request():
	return {'type': type.PLAYER_ROLL_REQUEST}

func fmt_player_pass_request():
	return {'type': type.PLAYER_PASS_REQUEST}

func fmt_player_move_request(from_idx:int, to_idx:int):
	return {'type': type.PLAYER_MOVE_REQUEST, 'from_idx': from_idx, 'to_idx': to_idx}

func fmt_game_state(state:GameState)->Dictionary:
	var pkt = state.fmt()
	pkt['type'] = type.GAME_STATE
	return pkt
