extends Node

enum marble_color {A, B, C, D, COUNT}

const marble_preload = preload("res://board/marble.tscn")
const materials = [
	preload("res://board/player_materials/A.tres"),
	preload("res://board/player_materials/B.tres"),
	preload("res://board/player_materials/C.tres"),
	preload("res://board/player_materials/D.tres")
]

func marble(color:int)->Spatial:
	assert(color >= 0 and color < marble_color.COUNT)
	var new_marble = marble_preload.instance()
	var mesh_instance = new_marble.find_node("MeshInstance")
	mesh_instance.mesh = mesh_instance.mesh.duplicate()
	mesh_instance.mesh.material = materials[color]
	return new_marble
