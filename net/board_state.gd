extends Object
class_name BoardState

var marbles:Array

func _init(array:Array=[])->void:
	marbles = []
	for p in range(4):
		marbles.append([])
		for _m in range(5):
			marbles[p].append(-1)
	
	if not array.is_empty():
		set_all(array)

func set_from(board_state)->void:
	set_all(board_state.marbles)

func set_all(array:Array)->void:
	assert(len(array) == 4)
	for player in range(len(array)):
		assert(array[player] is Array)
		assert(len(array[player]) == 5)
		for marble in range(len(array[player])):
			assert(array[player][marble] is int)
			marbles[player][marble] = array[player][marble]

func set_marble(player:int, marble:int, idx:int)->void:
	assert(0 <= player and player < 4)
	assert(0 <= marble and marble < 5)
	
	marbles[player][marble] = idx

func get_marble(player:int, marble:int)->int:
	return marbles[player][marble]

func get_marble_idx(player:int, idx:int)->int:
	return((marbles[player] as Array).find(idx))
