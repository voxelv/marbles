extends MainLoop

#var Logic = preload("res://logic.gd").new()
#var Config = preload("res://config.gd").new()
#var PKT = preload("res://net/pkt.gd").new()
#var Connection = preload("res://net/connection.gd").new()

var acc := 0.0

func _ready() -> void:
	print("ready")

func _finalize() -> void:
	print("finalize")

func _init() -> void:
	print("init")

func _iteration(delta: float) -> bool:
	acc += delta
	print("iteration %f" % acc)
	return(false)
