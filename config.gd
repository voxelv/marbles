extends Node

const GAME_REMOVAL_TIME = 100.0  # Seconds

var URL := "localhost"
var PORT := 9080

var game_key := ""

var is_server := false
var is_local := true

var number_of_games := 0
