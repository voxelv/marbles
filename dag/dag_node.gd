extends Node
class_name DAGNode

var idx:int

var next_main_track_node:Node = null

var next_center_node:Node = null
var next_position_node:Node = null
var next_home_row_node:Node = null

var is_home_row := false
var home_row_owner := 4

func _init(idx_in:int):
	idx = idx_in

