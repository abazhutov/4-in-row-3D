extends Node

# --- КОНСТАНТЫ / РЕСУРСЫ ---
var cell_scene = preload("res://Scenes/cell.tscn")
var piece_scene = preload("res://Scenes/piece.tscn")

# Материалы
var DarkMaterial = load("res://Materials/darkMaterial.tres")
var DarkAlphaMaterial = load("res://Materials/darkAlphaMaterial.tres")
var LightMaterial = load("res://Materials/lightMaterial.tres")
var LightAlphaMaterial = load("res://Materials/lightAlphaMaterial.tres")

# Размеры
var CELL_SIZE_X: float
var CELL_SIZE_Z: float
var CELL_SIZE_Y: float
var board_size: int
var board_offset: float

# Узлы
var root_node: Node3D # Ссылка на родительский Node3D (GameController)
var player_turn_label: Label
var game_status_label: Label
var ghost_piece: Node3D = null

# --- ИНИЦИАЛИЗАЦИЯ ---
func init(controller_node: Node3D, config: Dictionary):
	root_node = controller_node
	
	# Конфигурация
	CELL_SIZE_X = config.CELL_SIZE_X
	CELL_SIZE_Y = config.CELL_SIZE_Y
	CELL_SIZE_Z = config.CELL_SIZE_Z
	board_size = config.board_size
	board_offset = config.board_offset
	
	# Ссылки на UI
	player_turn_label = config.player_turn_label
	game_status_label = config.game_status_label

# --- ВИЗУАЛИЗАЦИЯ ДОСКИ ---
func clear_board():
	for child in root_node.get_children():
		if child.is_in_group("game_cell") or child.is_in_group("game_piece"):
			child.queue_free()	

func generate_board_cells(cell_clicked_handler, cell_hovered_handler, cell_unhovered_handler):
	for x in range(board_size):
		for z in range(board_size):
			create_cell(x, 0, z, cell_clicked_handler, cell_hovered_handler, cell_unhovered_handler)
				
func create_cell(x, y, z: int, click_handler, hovered_handler, unhovered_handler):			
	var cell = cell_scene.instantiate()
	
	# Расчет позиции для центрирования
	cell.position.x = x * CELL_SIZE_X - board_offset + CELL_SIZE_X / 2
	cell.position.z = z * CELL_SIZE_Z - board_offset + CELL_SIZE_Z / 2
	cell.position.y = y * CELL_SIZE_Y - board_offset + CELL_SIZE_Y / 2
	
	cell.set_coordinates(Vector3i(x, y, z))
	
	# Подключение сигналов (к методам GameController)
	cell.cell_clicked.connect(click_handler)
	cell.cell_hovered.connect(hovered_handler)
	cell.cell_unhovered.connect(unhovered_handler)
	
	root_node.add_child(cell)

# --- ВИЗУАЛИЗАЦИЯ ФИШЕК ---
func place_piece_visual(coords: Vector3i, player_id: int):
	var piece = piece_scene.instantiate()
	
	var cell_pos = get_cell_position_from_coords(coords)
	piece.position = cell_pos
	
	if player_id == 1:
		piece.get_node("MeshInstance3D").material_override = DarkMaterial
	else:
		piece.get_node("MeshInstance3D").material_override = LightMaterial
	
	root_node.add_child(piece)
	
func get_cell_position_from_coords(coords: Vector3i) -> Vector3:
	var x = coords.x
	var y = coords.y
	var z = coords.z
	
	var pos = Vector3.ZERO
	pos.x = x * CELL_SIZE_X - board_offset + CELL_SIZE_X / 2
	pos.z = z * CELL_SIZE_Z - board_offset + CELL_SIZE_Z / 2
	pos.y = y * CELL_SIZE_Y - board_offset + CELL_SIZE_Y / 2
	return pos

# --- ВИЗУАЛИЗАЦИЯ НАВЕДЕНИЯ (ПРИЗРАК) ---
func handle_hover_visuals(coords: Vector3i, current_player: int, is_empty: bool):
	if ghost_piece:
		ghost_piece.queue_free()
		ghost_piece = null
		
	if not is_empty:
		return
		
	var piece = piece_scene.instantiate()
	var cell_pos = get_cell_position_from_coords(coords)
	piece.position = cell_pos
	
	if current_player == 1:
		piece.get_node("MeshInstance3D").material_override = DarkAlphaMaterial
	else:
		piece.get_node("MeshInstance3D").material_override = LightAlphaMaterial
		
	root_node.add_child(piece)
	ghost_piece = piece

func clear_ghost_piece():
	if ghost_piece:
		ghost_piece.queue_free()
		ghost_piece = null

# --- UI ОБНОВЛЕНИЕ ---
func update_turn_display(current_player: int):
	var player_color = ""
	if current_player == 1:
		player_color = "Черных"
	else:
		player_color = "Белых"
		
	player_turn_label.text = "Ход: " + player_color

func show_game_status(winning_player: int, game_over_type: String):
	game_status_label.visible = true
	
	if game_over_type == "WIN":
		var player_name = "Черных" if winning_player == 1 else "Белых"
		game_status_label.text = "🏆 ПОБЕДА! Игрок за " + player_name + " выиграл!"
	elif game_over_type == "DRAW":
		game_status_label.text = "Ничья!"

func hide_game_status():
	game_status_label.visible = false
