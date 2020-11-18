extends Node

const GAME_REMOVAL_TIME = 20.0  # Seconds

var URL := "45.79.67.18"
#var URL := "localhost"
var PORT := 9080

var game_key := ""

var is_server := false
var is_local := true

var number_of_games := 0
