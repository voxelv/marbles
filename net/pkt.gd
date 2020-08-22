extends Node

enum type {NONE, CMD, BOARD, PLAYER_TURN_UPDATE, PLAYER_ROLL_REQUEST, PLAYER_ROLL_RESULT, SET_CLIENTINFO, PLAYER_MOVE_REQUEST}

enum cmd {NONE, PRINT_TEXT}

func fmt_cmd_print_text()->Dictionary:
	return {'type': type.CMD, 'cmd': cmd.PRINT_TEXT}

func fmt_board(board_state:BoardState)->Dictionary:
	return {'type': type.BOARD, 'board': board_state.marbles.duplicate()}

func fmt_player_turn_update(player:int):
	return {'type': type.PLAYER_TURN_UPDATE, 'player': player}

func fmt_player_roll_request():
	return {'type': type.PLAYER_ROLL_REQUEST}

func fmt_player_roll_result(roll_result:int):
	return {'type': type.PLAYER_ROLL_RESULT, 'result': roll_result}

func fmt_set_clientinfo(info:ClientInfo):
	return {'type': type.SET_CLIENTINFO, 'player': info.player, 'peer_id': info.peer_id, 'display_name': info.display_name}

func fmt_player_move_request(from_idx:int, to_idx:int):
	return {'type': type.PLAYER_MOVE_REQUEST, 'from_idx': from_idx, 'to_idx': to_idx}



