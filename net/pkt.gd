extends Node

enum type {NONE, CMD, BOARD}

enum cmd {NONE, PRINT_TEXT}

func fmt_cmd_print_text()->Dictionary:
	return {'type': type.CMD, 'cmd': cmd.PRINT_TEXT}

func fmt_board(board_state:Array)->Dictionary:
	return {'type': type.BOARD, 'board': board_state.duplicate()}








