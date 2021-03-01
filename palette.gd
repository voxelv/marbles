extends Node

enum color {PINK, GREEN, BLUE, YELLOW, CYAN, PURPLE, GRAY, COUNT}

const initial_colors := [color.PINK, color.GREEN, color.BLUE, color.YELLOW]
const avail_colors := {
	color.PINK: Color("ee6677"),
	color.GREEN: Color("228833"),
	color.BLUE: Color("4477aa"),
	color.YELLOW: Color("ccbb44"),
	color.CYAN: Color("66ccee"),
	color.PURPLE: Color("aa3377"),
	color.GRAY: Color("bbbbbb"),
}

const board_colors := {
	'5_run': "aaaaaa",
	'center': "f5de82",
	'edge': "8b8b8b",
	'home_entrance': "dcff6e",
	'home': "dad0ff",
	'home_row': "e7bbd7",
	'pokey_hole': "ffffff"
}
