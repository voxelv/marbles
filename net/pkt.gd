extends Node

enum type {NONE, CMD, BOARD, PLAYER_TURN_UPDATE}

enum cmd {NONE, PRINT_TEXT}

func fmt_cmd_print_text()->Dictionary:
	return {'type': type.CMD, 'cmd': cmd.PRINT_TEXT}

func fmt_board(board_state:BoardState)->Dictionary:
	return {'type': type.BOARD, 'board': board_state.marbles.duplicate()}

func fmt_player_turn_update(player:int):
	return {'type': type.PLAYER_TURN_UPDATE, 'player': player}






