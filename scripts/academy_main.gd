extends Control

const REF_GAME := preload("res://assets/supplied/v6_game.png")
const REF_GRID := preload("res://assets/supplied/v6_grid.png")
const REF_RESULTS := preload("res://assets/supplied/v6_adv.png")

const TITLE := 0
const PLAN := 1
const BATTLE := 2
const RESULT := 3

const BOARD_ORIGIN := Vector2(330.0, 140.0)
const CELL_SIZE := 82.0
const BOARD_COLS := 7
const BOARD_ROWS := 5
const BOARD_SIZE := Vector2(BOARD_COLS * CELL_SIZE, BOARD_ROWS * CELL_SIZE)

const BG := Color("#071229")
const BG_DEEP := Color("#040b18")
const PANEL := Color("#0b1a2d")
const PANEL_LIGHT := Color("#122844")
const CYAN := Color("#55e6d0")
const BLUE := Color("#63a8ff")
const AMBER := Color("#ffc857")
const MAGENTA := Color("#ef7ac8")
const MINT := Color("#7dffb2")
const TEXT := Color("#eef6ff")
const MUTED := Color("#91a9c6")
const DANGER := Color("#ff6f76")

var _font: Font
var _screen := TITLE
var _selected_loadout := 0
var _plan_units: Array[Dictionary] = []
var _plan_modules: Array[Dictionary] = []
var _battle_units: Array[Dictionary] = []
var _enemies: Array[Dictionary] = []
var _battle_modules: Array[Dictionary] = []
var _selected_unit := 0
var _turn := 1
var _action_points := 2
var _score := 0
var _accreditation := 0
var _result_won := false
var _feedback := "Select a cell to shape the test."
var _feedback_color := CYAN
var _pulse_time := 0.0
var _last_click_cell := Vector2i(-1, -1)

func _ready() -> void:
	_font = ThemeDB.fallback_font
	custom_minimum_size = Vector2(1280.0, 720.0)
	_reset_plan()
	queue_redraw()

func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_click(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)

func _handle_key(key: Key) -> void:
	if key == KEY_ESCAPE:
		if _screen == TITLE:
			return
		if _screen == BATTLE:
			_screen = PLAN
			_feedback = "Test paused. Revise the academy plan or begin again."
		elif _screen == RESULT:
			_screen = PLAN
		else:
			_screen = TITLE
		queue_redraw()
		return
	if _screen == TITLE and (key == KEY_ENTER or key == KEY_SPACE):
		_begin_plan()
	elif _screen == PLAN:
		if key == KEY_1:
			_selected_loadout = 0
		elif key == KEY_2:
			_selected_loadout = 1
		elif key == KEY_3:
			_selected_loadout = 2
		elif key == KEY_R:
			_reset_plan()
		elif key == KEY_ENTER:
			_start_test()
	elif _screen == BATTLE:
		if key == KEY_SPACE:
			_pulse_strike()
		elif key == KEY_TAB:
			_end_turn()
	queue_redraw()

func _handle_click(position: Vector2) -> void:
	if _screen == TITLE:
		if Rect2(64.0, 510.0, 330.0, 58.0).has_point(position):
			_begin_plan()
	elif _screen == PLAN:
		_handle_plan_click(position)
	elif _screen == BATTLE:
		_handle_battle_click(position)
	elif _screen == RESULT:
		if Rect2(66.0, 530.0, 300.0, 56.0).has_point(position):
			_begin_plan()
		elif Rect2(390.0, 530.0, 300.0, 56.0).has_point(position):
			_start_test()
		elif Rect2(714.0, 530.0, 300.0, 56.0).has_point(position):
			_screen = TITLE
		queue_redraw()

func _begin_plan() -> void:
	_screen = PLAN
	_feedback = "Plan the arena, deploy a roster, then run the tactical test."
	_feedback_color = CYAN
	queue_redraw()

func _reset_plan() -> void:
	_plan_units = [
		{"name": "Astra", "role": "VANGUARD", "pos": Vector2i(0, 2), "hp": 5, "max_hp": 5, "cooldown": 0, "color": BLUE},
		{"name": "Nova", "role": "FLUX MAGE", "pos": Vector2i(1, 3), "hp": 4, "max_hp": 4, "cooldown": 0, "color": MAGENTA}
	]
	_plan_modules = [{"name": "AEGIS BEACON", "pos": Vector2i(2, 2), "color": AMBER}]
	_selected_loadout = 0
	_feedback = "Loadout restored. Add a cadet or reposition a module."
	_feedback_color = AMBER

func _handle_plan_click(position: Vector2) -> void:
	for i in range(3):
		if Rect2(42.0, 188.0 + i * 78.0, 242.0, 60.0).has_point(position):
			_selected_loadout = i
			_feedback = _loadout_hint(i)
			_feedback_color = _loadout_color(i)
			return
	if Rect2(42.0, 450.0, 242.0, 48.0).has_point(position):
		_reset_plan()
		return
	if Rect2(952.0, 506.0, 270.0, 56.0).has_point(position):
		_start_test()
		return
	if Rect2(952.0, 574.0, 270.0, 44.0).has_point(position):
		_reset_plan()
		return
	if _is_inside_board(position):
		var cell := _cell_from_point(position)
		_last_click_cell = cell
		if _cell_occupied(cell):
			_feedback = "That cell is already assigned. Choose an open cell."
			_feedback_color = DANGER
			return
		if _selected_loadout == 2:
			_plan_modules.append({"name": "AEGIS BEACON", "pos": cell, "color": AMBER})
			_feedback = "Aegis Beacon deployed. The test will expose its safe lane."
		else:
			var loadout := _unit_for_loadout(_selected_loadout, cell)
			_plan_units.append(loadout)
			_feedback = "%s deployed. The test will expose its role and cooldown." % str(loadout["name"])
		_feedback_color = MINT

func _start_test() -> void:
	if _plan_units.is_empty():
		_reset_plan()
	_battle_units = []
	for unit in _plan_units:
		_battle_units.append(unit.duplicate(true))
	_battle_modules = []
	for module in _plan_modules:
		_battle_modules.append(module.duplicate(true))
	_enemies = [
		{"name": "RIVAL WARDEN", "role": "RIVAL", "pos": Vector2i(6, 1), "hp": 4, "max_hp": 4, "cooldown": 0, "color": DANGER},
		{"name": "NULL DRONE", "role": "RIVAL", "pos": Vector2i(5, 3), "hp": 3, "max_hp": 3, "cooldown": 0, "color": MAGENTA}
	]
	_selected_unit = 0
	_turn = 1
	_action_points = 2
	_score = 0
	_accreditation = 0
	_screen = BATTLE
	_feedback = "Your turn. Select a cadet, then move one cell or pulse-strike a rival."
	_feedback_color = CYAN

func _handle_battle_click(position: Vector2) -> void:
	if Rect2(950.0, 592.0, 132.0, 50.0).has_point(position):
		_pulse_strike()
		return
	if Rect2(1090.0, 592.0, 132.0, 50.0).has_point(position):
		_end_turn()
		return
	if not _is_inside_board(position):
		return
	var cell := _cell_from_point(position)
	_last_click_cell = cell
	var unit_index := _unit_index_at(_battle_units, cell)
	if unit_index >= 0:
		_selected_unit = unit_index
		_feedback = "%s selected. Range 3 · Move 1 · 2 AP." % str(_battle_units[unit_index]["name"])
		_feedback_color = _unit_color(_battle_units[unit_index])
		return
	var enemy_index := _unit_index_at(_enemies, cell)
	if enemy_index >= 0:
		_attack_enemy(enemy_index)
		return
	if _selected_unit >= 0 and _selected_unit < _battle_units.size():
		_move_selected(cell)

func _move_selected(cell: Vector2i) -> void:
	if _action_points <= 0:
		_feedback = "No action points left. End the turn to let the rival respond."
		_feedback_color = DANGER
		return
	var current: Vector2i = _battle_units[_selected_unit]["pos"]
	if _manhattan(current, cell) != 1:
		_feedback = "Cadets move one orthogonal cell per action."
		_feedback_color = AMBER
		return
	if _cell_occupied_battle(cell):
		_feedback = "That cell is occupied. Read the highlighted range and choose another."
		_feedback_color = DANGER
		return
	_battle_units[_selected_unit]["pos"] = cell
	_action_points -= 1
	_score += 10
	_feedback = "%s moved. Positioning improves the next pulse strike." % str(_battle_units[_selected_unit]["name"])
	_feedback_color = MINT

func _attack_enemy(enemy_index: int) -> void:
	if _selected_unit < 0 or _selected_unit >= _battle_units.size():
		_feedback = "Select a cadet before targeting a rival."
		_feedback_color = AMBER
		return
	if _action_points <= 0:
		_feedback = "No action points left. End the turn to continue the drill."
		_feedback_color = DANGER
		return
	var origin: Vector2i = _battle_units[_selected_unit]["pos"]
	var target: Vector2i = _enemies[enemy_index]["pos"]
	if _manhattan(origin, target) > 3:
		_feedback = "That rival is outside the pulse range of this cadet."
		_feedback_color = AMBER
		return
	var cooldown := int(_battle_units[_selected_unit]["cooldown"])
	if cooldown > 0:
		_feedback = "Pulse strike is cooling down for %d turn(s)." % cooldown
		_feedback_color = DANGER
		return
	var damage := 2
	if str(_battle_units[_selected_unit]["role"]) == "FLUX MAGE":
		damage = 3
	_battle_units[_selected_unit]["cooldown"] = 2
	_action_points -= 1
	_enemies[enemy_index]["hp"] = int(_enemies[enemy_index]["hp"]) - damage
	_score += damage * 25
	_feedback = "%s hit %s for %d. Cooldown 2." % [str(_battle_units[_selected_unit]["name"]), str(_enemies[enemy_index]["name"]), damage]
	_feedback_color = CYAN
	if int(_enemies[enemy_index]["hp"]) <= 0:
		_score += 80
		_feedback = "%s disabled. Rival formation weakening." % str(_enemies[enemy_index]["name"])
		_enemies.remove_at(enemy_index)
	_check_battle_end()

func _pulse_strike() -> void:
	if _selected_unit < 0 or _selected_unit >= _battle_units.size():
		_feedback = "Select a cadet before using Pulse Strike."
		_feedback_color = AMBER
		return
	if _action_points <= 0:
		_feedback = "No action points left. End the turn to continue the drill."
		_feedback_color = DANGER
		return
	var cooldown := int(_battle_units[_selected_unit]["cooldown"])
	if cooldown > 0:
		_feedback = "Pulse Strike ready in %d turn(s)." % cooldown
		_feedback_color = DANGER
		return
	var origin: Vector2i = _battle_units[_selected_unit]["pos"]
	var closest := -1
	var closest_distance := 99
	for i in range(_enemies.size()):
		var distance := _manhattan(origin, _enemies[i]["pos"])
		if distance <= 3 and distance < closest_distance:
			closest = i
			closest_distance = distance
	if closest < 0:
		_feedback = "No rival is within the three-cell pulse radius. Move into range."
		_feedback_color = AMBER
		return
	_attack_enemy(closest)

func _end_turn() -> void:
	if _screen != BATTLE:
		return
	for i in range(_battle_units.size()):
		_battle_units[i]["cooldown"] = maxi(0, int(_battle_units[i]["cooldown"]) - 1)
	for enemy in _enemies:
		enemy["cooldown"] = maxi(0, int(enemy["cooldown"]) - 1)
	for enemy in _enemies:
		if _battle_units.is_empty():
			break
		var target_index := _closest_unit_index(enemy["pos"])
		if target_index < 0:
			break
		var target_pos: Vector2i = _battle_units[target_index]["pos"]
		if _manhattan(enemy["pos"], target_pos) <= 2:
			_battle_units[target_index]["hp"] = int(_battle_units[target_index]["hp"]) - 1
			_feedback = "%s struck %s. Protect the roster with the Aegis Beacon." % [str(enemy["name"]), str(_battle_units[target_index]["name"])]
			_feedback_color = DANGER
		else:
			var step := _step_toward(enemy["pos"], target_pos)
			if not _cell_occupied_battle(step):
				enemy["pos"] = step
	_turn += 1
	_action_points = 2
	_check_battle_end()

func _check_battle_end() -> void:
	var survivors := 0
	for unit in _battle_units:
		if int(unit["hp"]) > 0:
			survivors += 1
	if _enemies.is_empty():
		_result_won = true
		_accreditation = 100 + maxi(0, 20 - _turn * 2)
		_score += 250 + _accreditation
		_screen = RESULT
		_feedback = ""
	elif survivors == 0:
		_result_won = false
		_accreditation = 35
		_screen = RESULT
		_feedback = ""
	else:
		var dead_index := -1
		for i in range(_battle_units.size()):
			if int(_battle_units[i]["hp"]) <= 0:
				dead_index = i
				break
		if dead_index >= 0:
			_battle_units.remove_at(dead_index)
			_selected_unit = clampi(_selected_unit, 0, maxi(0, _battle_units.size() - 1))

func _draw() -> void:
	if _font == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BG_DEEP, true)
	if _screen == TITLE:
		_draw_title()
	elif _screen == PLAN:
		_draw_plan()
	elif _screen == BATTLE:
		_draw_battle()
	elif _screen == RESULT:
		_draw_result()

func _draw_title() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), BG, true)
	for i in range(7):
		var y := 86.0 + i * 78.0
		draw_line(Vector2(0.0, y), Vector2(1280.0, y), Color(0.12, 0.3, 0.42, 0.16), 1.0)
	draw_circle(Vector2(620.0, 360.0), 250.0 + sin(_pulse_time) * 4.0, Color(0.1, 0.65, 0.7, 0.045), false, 2.0)
	_panel(Rect2(52.0, 52.0, 560.0, 608.0), Color(0.03, 0.08, 0.15, 0.92), CYAN)
	_text("ACADEMY OPERATIONS / 01", Vector2(88.0, 114.0), 15, CYAN)
	_text("HERO", Vector2(84.0, 194.0), 76, TEXT)
	_text("ACADEMY", Vector2(84.0, 270.0), 76, TEXT)
	_text("ARCHITECT", Vector2(84.0, 346.0), 76, AMBER)
	_text("Design the test. Train the roster. Outthink the rival.", Vector2(88.0, 397.0), 19, MUTED)
	_text("A focused turn-based tactics lab", Vector2(88.0, 430.0), 14, MUTED)
	_text("built from the supplied academy foundation.", Vector2(88.0, 452.0), 14, MUTED)
	_button(Rect2(64.0, 510.0, 330.0, 58.0), "ENTER TACTICS LAB", true)
	_text("ENTER / SPACE", Vector2(410.0, 545.0), 12, MUTED)
	_text("SUPPLIED VISUAL LANGUAGE", Vector2(716.0, 60.0), 13, CYAN)
	_panel(Rect2(700.0, 84.0, 528.0, 320.0), PANEL, Color("#294970"))
	draw_texture_rect(REF_GAME, Rect2(716.0, 100.0, 496.0, 279.0), false)
	draw_rect(Rect2(716.0, 100.0, 496.0, 279.0), Color(0.02, 0.05, 0.09, 0.2), true)
	_text("PLANNING / FACILITIES / TACTICS", Vector2(716.0, 430.0), 13, AMBER)
	_text("The captured academy dashboard is now a playable command loop.", Vector2(716.0, 458.0), 16, TEXT)
	_text("v6 source package integrated", Vector2(716.0, 488.0), 13, MUTED)
	_text("LOCAL SINGLE-PLAYER · DESKTOP", Vector2(88.0, 630.0), 12, Color("#5f7c9d"))

func _draw_plan() -> void:
	_draw_top_bar("ACADEMY PLANNING", "SHAPE THE TEST", "DESIGN PHASE")
	_panel(Rect2(24.0, 96.0, 278.0, 536.0), PANEL, Color("#2f5574"))
	_text("LOADOUT", Vector2(42.0, 130.0), 15, CYAN)
	_text("Deploy roles before the rival enters.", Vector2(42.0, 154.0), 13, MUTED)
	for i in range(3):
		var rect := Rect2(42.0, 188.0 + i * 78.0, 242.0, 60.0)
		var chosen := i == _selected_loadout
		_panel(rect, Color(0.12, 0.24, 0.38, 0.92) if chosen else Color(0.05, 0.12, 0.21, 0.9), _loadout_color(i) if chosen else Color("#203b58"))
		_text("0%d" % (i + 1), rect.position + Vector2(14.0, 24.0), 12, _loadout_color(i))
		_text(_loadout_name(i), rect.position + Vector2(46.0, 24.0), 15, TEXT)
		_text(_loadout_desc(i), rect.position + Vector2(46.0, 44.0), 11, MUTED)
	_button(Rect2(42.0, 450.0, 242.0, 48.0), "RESET LAYOUT", false)
	_text("CLICK A CELL TO DEPLOY", Vector2(42.0, 542.0), 11, MUTED)
	_text("1–3 SELECT ROLE  ·  R RESET", Vector2(42.0, 566.0), 11, Color("#5f7c9d"))
	_draw_board("ARENA BLUEPRINT", false)
	_panel(Rect2(936.0, 96.0, 316.0, 536.0), PANEL, Color("#2f5574"))
	_text("SUPPLIED BLUEPRINT", Vector2(956.0, 130.0), 13, CYAN)
	draw_texture_rect(REF_GRID, Rect2(956.0, 148.0, 276.0, 155.0), false)
	draw_rect(Rect2(956.0, 148.0, 276.0, 155.0), Color(0.02, 0.05, 0.09, 0.3), true)
	_text("DESIGN BRIEF", Vector2(956.0, 337.0), 12, AMBER)
	_text("1  Establish a safe entry lane.", Vector2(956.0, 363.0), 13, TEXT)
	_text("2  Pair a cadet with a module.", Vector2(956.0, 387.0), 13, TEXT)
	_text("3  Read cooldowns during the test.", Vector2(956.0, 411.0), 13, TEXT)
	_panel(Rect2(956.0, 440.0, 276.0, 46.0), Color(0.04, 0.13, 0.2, 0.9), _feedback_color)
	_text(_feedback, Vector2(968.0, 468.0), 11, _feedback_color, 252.0)
	_button(Rect2(952.0, 506.0, 270.0, 56.0), "BEGIN TACTICAL TEST", true)
	_button(Rect2(952.0, 574.0, 270.0, 44.0), "REVISE / RESET", false)

func _draw_battle() -> void:
	_draw_top_bar("TACTICAL TEST", "TURN %02d" % _turn, "LIVE DRILL")
	_panel(Rect2(24.0, 96.0, 278.0, 536.0), PANEL, Color("#2f5574"))
	_text("ACADEMY ROSTER", Vector2(42.0, 130.0), 15, CYAN)
	_text("ACTION POINTS", Vector2(42.0, 160.0), 11, MUTED)
	for i in range(_battle_units.size()):
		var unit: Dictionary = _battle_units[i]
		var rect := Rect2(42.0, 184.0 + i * 92.0, 242.0, 72.0)
		var selected := i == _selected_unit
		_panel(rect, Color(0.12, 0.24, 0.38, 0.96) if selected else Color(0.05, 0.12, 0.21, 0.9), _unit_color(unit) if selected else Color("#203b58"))
		_text(str(unit["name"]), rect.position + Vector2(14.0, 23.0), 15, TEXT)
		_text(str(unit["role"]), rect.position + Vector2(14.0, 44.0), 11, _unit_color(unit))
		_text("HP %d/%d" % [int(unit["hp"]), int(unit["max_hp"])], rect.position + Vector2(154.0, 23.0), 12, TEXT)
		_text("CD %d" % int(unit["cooldown"]), rect.position + Vector2(154.0, 45.0), 11, AMBER if int(unit["cooldown"]) > 0 else MINT)
	_text("MOVE: click adjacent cell", Vector2(42.0, 420.0), 12, MUTED)
	_text("PULSE: target within 3 cells", Vector2(42.0, 444.0), 12, MUTED)
	_text("SPACE: pulse strike", Vector2(42.0, 468.0), 12, MUTED)
	_text("TAB: end turn", Vector2(42.0, 492.0), 12, MUTED)
	_panel(Rect2(42.0, 532.0, 242.0, 66.0), Color(0.04, 0.13, 0.2, 0.94), _feedback_color)
	_text(_feedback, Vector2(54.0, 554.0), 11, _feedback_color, 218.0)
	_draw_board("TACTICAL GRID", true)
	_panel(Rect2(936.0, 96.0, 316.0, 536.0), PANEL, Color("#2f5574"))
	_text("RIVAL THREAT", Vector2(956.0, 130.0), 13, DANGER)
	_text("A rival formation is probing your layout.", Vector2(956.0, 156.0), 13, MUTED, 270.0)
	for i in range(_enemies.size()):
		var enemy: Dictionary = _enemies[i]
		var y := 196.0 + i * 62.0
		draw_circle(Vector2(968.0, y - 5.0), 10.0, DANGER if i == 0 else MAGENTA)
		_text(str(enemy["name"]), Vector2(988.0, y), 13, TEXT)
		_text("HP %d/%d" % [int(enemy["hp"]), int(enemy["max_hp"])], Vector2(988.0, y + 20.0), 11, MUTED)
	_text("TACTICAL READOUT", Vector2(956.0, 342.0), 12, AMBER)
	_text("Terrain: OPEN CAMPUS", Vector2(956.0, 368.0), 12, TEXT)
	_text("Synergy: AEGIS + VANGUARD", Vector2(956.0, 392.0), 12, TEXT)
	_text("Cooldowns: visible on roster", Vector2(956.0, 416.0), 12, TEXT)
	_panel(Rect2(956.0, 448.0, 276.0, 72.0), Color(0.05, 0.12, 0.21, 0.94), Color("#294970"))
	_text("AP %d / 2" % _action_points, Vector2(972.0, 476.0), 22, CYAN)
	_text("Every move or pulse spends 1 AP.", Vector2(972.0, 500.0), 11, MUTED)
	_button(Rect2(950.0, 592.0, 132.0, 50.0), "PULSE STRIKE", true)
	_button(Rect2(1090.0, 592.0, 132.0, 50.0), "END TURN", false)

func _draw_result() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), BG, true)
	_panel(Rect2(44.0, 44.0, 1180.0, 612.0), Color(0.03, 0.08, 0.15, 0.98), CYAN if _result_won else DANGER)
	_text("ACADEMY ARCHIVE / TEST RESULT", Vector2(78.0, 94.0), 14, CYAN)
	_text("ACCREDITATION", Vector2(78.0, 182.0), 54, MINT if _result_won else DANGER)
	_text("GRANTED" if _result_won else "DEFERRED", Vector2(78.0, 238.0), 54, TEXT)
	_text("The roster %s the rival drill." % ("mastered" if _result_won else "could not clear"), Vector2(82.0, 282.0), 18, MUTED)
	_panel(Rect2(78.0, 326.0, 286.0, 118.0), Color(0.05, 0.14, 0.22, 0.9), MINT if _result_won else DANGER)
	_text("SCORE", Vector2(98.0, 360.0), 12, MUTED)
	_text("%04d" % _score, Vector2(98.0, 410.0), 42, TEXT)
	_panel(Rect2(390.0, 326.0, 286.0, 118.0), Color(0.05, 0.14, 0.22, 0.9), AMBER)
	_text("ACCREDITATION", Vector2(410.0, 360.0), 12, MUTED)
	_text("%d%%" % _accreditation, Vector2(410.0, 410.0), 42, AMBER)
	_panel(Rect2(714.0, 102.0, 470.0, 342.0), PANEL, Color("#294970"))
	draw_texture_rect(REF_RESULTS, Rect2(734.0, 122.0, 430.0, 242.0), false)
	draw_rect(Rect2(734.0, 122.0, 430.0, 242.0), Color(0.02, 0.05, 0.09, 0.28), true)
	_text("REPLAYABLE OUTCOME", Vector2(734.0, 402.0), 13, AMBER)
	_text("Revise the academy plan when a test fails.", Vector2(734.0, 430.0), 14, TEXT)
	_button(Rect2(66.0, 530.0, 300.0, 56.0), "REVISE ACADEMY PLAN", true)
	_button(Rect2(390.0, 530.0, 300.0, 56.0), "RUN ANOTHER DRILL", false)
	_button(Rect2(714.0, 530.0, 300.0, 56.0), "RETURN TO TITLE", false)
	_text("The supplied Hero Academy visual language remains part of the archive.", Vector2(78.0, 622.0), 12, MUTED)

func _draw_top_bar(section: String, middle: String, phase: String) -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 76.0), Color("#06101e"), true)
	draw_line(Vector2(0.0, 75.0), Vector2(1280.0, 75.0), CYAN, 1.0)
	_text(section, Vector2(28.0, 31.0), 16, CYAN)
	_text(phase, Vector2(28.0, 54.0), 11, MUTED)
	_text(middle, Vector2(560.0, 44.0), 24, TEXT)
	_text("DAY 03  ·  HERO ACADEMY", Vector2(1010.0, 31.0), 12, AMBER)
	_text("LOCAL TRAINING INSTANCE", Vector2(1010.0, 52.0), 11, MUTED)

func _draw_board(label: String, tactical: bool) -> void:
	_panel(Rect2(312.0, 96.0, 604.0, 536.0), Color(0.03, 0.1, 0.16, 0.96), Color("#294970"))
	_text(label, Vector2(334.0, 126.0), 13, CYAN)
	_text("7 × 5 CAMPUS GRID", Vector2(756.0, 126.0), 11, MUTED)
	for y in range(BOARD_ROWS):
		for x in range(BOARD_COLS):
			var cell := Vector2i(x, y)
			var rect := _cell_rect(cell)
			var fill := Color("#102b43") if (x + y) % 2 == 0 else Color("#0d2439")
			if tactical and _selected_unit >= 0 and _selected_unit < _battle_units.size():
				var origin: Vector2i = _battle_units[_selected_unit]["pos"]
				var distance := _manhattan(origin, cell)
				if distance <= 3:
					fill = Color(0.08, 0.34, 0.36, 0.72)
			if cell == _last_click_cell:
				fill = Color(0.18, 0.46, 0.5, 0.9)
			draw_rect(rect, fill, true)
			draw_rect(rect, Color(0.3, 0.56, 0.7, 0.32), false, 1.0)
			if x == 3 and y == 1:
				draw_circle(rect.position + rect.size * 0.5, 4.0, Color(0.35, 0.7, 0.78, 0.4))
	for module in (_battle_modules if tactical else _plan_modules):
		_draw_module(module)
	for unit in (_battle_units if tactical else _plan_units):
		_draw_cadet(unit)
	if tactical:
		for enemy in _enemies:
			_draw_enemy(enemy)

func _draw_cadet(unit: Dictionary) -> void:
	var center := _cell_center(unit["pos"])
	var color: Color = _unit_color(unit)
	draw_circle(center, 23.0, Color(0.02, 0.07, 0.13, 0.94))
	draw_circle(center, 20.0, color)
	draw_circle(center, 20.0, Color(0.9, 1.0, 1.0, 0.75), false, 2.0)
	_text(_role_glyph(str(unit["role"])), center + Vector2(-7.0, 7.0), 18, BG_DEEP)
	_text(str(unit["name"]), center + Vector2(-31.0, -28.0), 11, TEXT)
	_draw_hp_bar(center + Vector2(-25.0, 28.0), int(unit["hp"]), int(unit["max_hp"]), color)

func _draw_enemy(enemy: Dictionary) -> void:
	var center := _cell_center(enemy["pos"])
	var color: Color = enemy["color"]
	draw_circle(center, 22.0, Color(0.18, 0.03, 0.13, 0.94))
	draw_circle(center, 18.0, color)
	draw_circle(center, 18.0 + sin(_pulse_time * 3.0) * 2.0, Color(1.0, 0.4, 0.52, 0.45), false, 2.0)
	_text("R", center + Vector2(-6.0, 7.0), 17, BG_DEEP)
	_text(str(enemy["name"]), center + Vector2(-34.0, -27.0), 10, Color("#ffd2df"))
	_draw_hp_bar(center + Vector2(-25.0, 27.0), int(enemy["hp"]), int(enemy["max_hp"]), color)

func _draw_module(module: Dictionary) -> void:
	var center := _cell_center(module["pos"])
	var color: Color = module["color"]
	draw_rect(Rect2(center - Vector2(21.0, 21.0), Vector2(42.0, 42.0)), Color(0.22, 0.13, 0.03, 0.95), true)
	draw_rect(Rect2(center - Vector2(18.0, 18.0), Vector2(36.0, 36.0)), color, false, 3.0)
	draw_line(center - Vector2(12.0, 0.0), center + Vector2(12.0, 0.0), color, 2.0)
	draw_line(center - Vector2(0.0, 12.0), center + Vector2(0.0, 12.0), color, 2.0)
	_text("AEGIS", center + Vector2(-24.0, 33.0), 10, AMBER)

func _draw_hp_bar(origin: Vector2, hp: int, max_hp: int, color: Color) -> void:
	var width := 50.0
	draw_rect(Rect2(origin, Vector2(width, 5.0)), Color(0.02, 0.04, 0.08, 0.9), true)
	if max_hp > 0:
		draw_rect(Rect2(origin, Vector2(width * clampf(float(hp) / float(max_hp), 0.0, 1.0), 5.0)), color, true)

func _button(rect: Rect2, label: String, accent: bool) -> void:
	var fill := Color(0.08, 0.34, 0.36, 0.96) if accent else Color(0.08, 0.16, 0.27, 0.96)
	var border := CYAN if accent else Color("#426485")
	_panel(rect, fill, border)
	_center_text(label, rect, 13, TEXT)

func _panel(rect: Rect2, fill: Color, border: Color) -> void:
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 1.0)

func _text(value: String, position: Vector2, font_size: int, color: Color = TEXT, width: float = -1.0) -> void:
	draw_string(_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _center_text(value: String, rect: Rect2, font_size: int, color: Color) -> void:
	draw_string(_font, rect.position + Vector2(0.0, rect.size.y * 0.5 + font_size * 0.35), value, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(BOARD_ORIGIN + Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))

func _cell_center(cell: Vector2i) -> Vector2:
	return BOARD_ORIGIN + Vector2(cell.x * CELL_SIZE + CELL_SIZE * 0.5, cell.y * CELL_SIZE + CELL_SIZE * 0.5)

func _is_inside_board(position: Vector2) -> bool:
	return Rect2(BOARD_ORIGIN, BOARD_SIZE).has_point(position)

func _cell_from_point(position: Vector2) -> Vector2i:
	return Vector2i(int(floor((position.x - BOARD_ORIGIN.x) / CELL_SIZE)), int(floor((position.y - BOARD_ORIGIN.y) / CELL_SIZE)))

func _cell_occupied(cell: Vector2i) -> bool:
	return _unit_index_at(_plan_units, cell) >= 0 or _unit_index_at(_plan_modules, cell) >= 0

func _cell_occupied_battle(cell: Vector2i) -> bool:
	return _unit_index_at(_battle_units, cell) >= 0 or _unit_index_at(_enemies, cell) >= 0 or _unit_index_at(_battle_modules, cell) >= 0

func _unit_index_at(collection: Array[Dictionary], cell: Vector2i) -> int:
	for i in range(collection.size()):
		if collection[i].get("pos", Vector2i(-10, -10)) == cell:
			return i
	return -1

func _unit_for_loadout(index: int, cell: Vector2i) -> Dictionary:
	if index == 1:
		return {"name": "Nova", "role": "FLUX MAGE", "pos": cell, "hp": 4, "max_hp": 4, "cooldown": 0, "color": MAGENTA}
	return {"name": "Astra", "role": "VANGUARD", "pos": cell, "hp": 5, "max_hp": 5, "cooldown": 0, "color": BLUE}

func _loadout_name(index: int) -> String:
	return ["VANGUARD", "FLUX MAGE", "AEGIS BEACON"][index]

func _loadout_desc(index: int) -> String:
	return ["5 HP  ·  steady pulse", "4 HP  ·  high damage", "module  ·  protects lane"][index]

func _loadout_hint(index: int) -> String:
	return ["Vanguard selected. Place an Astra on an open cell.", "Flux Mage selected. Nova hits harder but needs timing.", "Aegis Beacon selected. Modules shape the safe lane."][index]

func _loadout_color(index: int) -> Color:
	return [BLUE, MAGENTA, AMBER][index]

func _unit_color(unit: Dictionary) -> Color:
	return unit.get("color", BLUE)

func _role_glyph(role: String) -> String:
	if role == "FLUX MAGE":
		return "N"
	return "A"

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _closest_unit_index(origin: Vector2i) -> int:
	var closest := -1
	var best := 999
	for i in range(_battle_units.size()):
		var distance := _manhattan(origin, _battle_units[i]["pos"])
		if distance < best:
			best = distance
			closest = i
	return closest

func _step_toward(origin: Vector2i, target: Vector2i) -> Vector2i:
	var delta := target - origin
	if abs(delta.x) >= abs(delta.y) and delta.x != 0:
		return origin + Vector2i(sign(delta.x), 0)
	if delta.y != 0:
		return origin + Vector2i(0, sign(delta.y))
	return origin
