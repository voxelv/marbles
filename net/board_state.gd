extends Node
class_name BoardState

var marbles:Array

func _init(array:Array=[])->void:
	marbles = []
	for p in range(Logic.player.COUNT):
		marbles.append([])
		for m in range(Logic.NUM_MARBLES_PER_PLAYER):
			marbles[p].append(-1)
	
	if not array.empty():
		set_all(array)

func set_from(board_state:BoardState)->void:
	set_all(board_state.marbles)

func set_all(array:Array)->void:
	assert(len(array) == Logic.player.COUNT)
	for player in range(len(array)):
		assert(array[player] is Array)
		assert(len(array[player]) == Logic.NUM_MARBLES_PER_PLAYER)
		for marble in range(len(array[player])):
			assert(array[player][marble] is int)
			marbles[player][marble] = array[player][marble]

func set_marble(player:int, marble:int, idx:int)->void:
	assert(0 <= player and player < Logic.player.COUNT)
	assert(0 <= marble and marble < Logic.NUM_MARBLES_PER_PLAYER)
	
	marbles[player][marble] = idx

func get_marble(player:int, marble:int)->int:
	return marbles[player][marble]

func get_marble_idx(player:int, idx:int)->int:
	return((marbles[player] as Array).find(idx))

