extends Node3D

var cell_scene = preload("res://cell.tscn")
var piece_scene = preload("res://piece.tscn") # Сцена вашей фишки

var DarkMaterial = load("res://Materials/darkMaterial.tres")
var DarkAlphaMaterial = load("res://Materials/darkAlphaMaterial.tres")
var LightMaterial = load("res://Materials/lightMaterial.tres")
var LightAlphaMaterial = load("res://Materials/lightAlphaMaterial.tres")
var TransparentMaterial = load("res://Materials/alpa0.tres")

@onready var player_turn_label: Label = $"CanvasLayer/ControlPlayerTurn/LabelPlayerTurn"
@onready var game_status_label: Label = $"CanvasLayer/ControlGameStatus/LabelGameStatus"

const CELL_SIZE_X = 1.0
const CELL_SIZE_Z = 1.0
const CELL_SIZE_Y = 0.5

const board_size = 5 # 5x5x5
var board_offset = float(board_size) / 2.0
var current_player = 1 # 1: Игрок 1 (Black), 2: Игрок 2/AI (White)
var game_over = false

# --- МОДЕЛЬ ИГРЫ ---
const EMPTY = 0
const PLAYER_1 = 1
const PLAYER_2 = 2
var board_state: Array = [] # 3D-массив для хранения состояния: board_state[x][y][z]

var ghost_piece: Node3D = null # Ссылка на текущую полупрозрачную фишку

func _ready():
	reset_game()

func reset_game():
	# основу доски в начало кодинат по высоте
	$Plane.position.y = - board_offset
	
	game_over = false # Сбрасываем флаг
	game_status_label.visible = false # Скрываем сообщение
	
	if ghost_piece:
		ghost_piece.queue_free()
		ghost_piece = null
		
	clear_board()
	board_state.clear()
	init_board_state()
	generate_board_cells()

	update_turn_display() # Показываем первый ход
	current_player = PLAYER_1
	print("Игра перезапущена. Ход игрока ", current_player)
	# return

func clear_board():
	for child in get_children():
		if child.is_in_group("game_cell") or child.is_in_group("game_piece"):
			child.queue_free()	

func init_board_state():
	# Инициализация 3D-массива [5][5][5]
	for x in range(board_size):
		board_state.append([])
		for y in range(board_size):
			board_state[x].append([])
			for z in range(board_size):
				board_state[x][y].append(EMPTY) # Каждая ячейка изначально пуста

func generate_board_cells():
	# Генерация ячеек и их центрирование
	for x in range(board_size):
		for z in range(board_size):
			create_cell(x,0,z)
				
func create_cell(x,y,z: int):			
	var cell = cell_scene.instantiate()
	
	# Расчет позиции для центрирования
	cell.position.x = x * CELL_SIZE_X - board_offset + CELL_SIZE_X / 2 
	cell.position.z = z * CELL_SIZE_Z - board_offset + CELL_SIZE_Z / 2
	cell.position.y = y * CELL_SIZE_Y - board_offset + CELL_SIZE_Y / 2
	# 1. Передача логических координат ячейке
	cell.set_coordinates(Vector3i(x, y, z))
	# 2. Подключение сигналов: при клике вызывается метод _on_cell_clicked
	cell.cell_clicked.connect(_on_cell_clicked)
	cell.cell_hovered.connect(_on_cell_hovered)
	cell.cell_unhovered.connect(_on_cell_unhovered) # Для очистки, когда мышь уходит
	
	add_child(cell)
	
func update_turn_display():
	var player_color = ""
	if current_player == PLAYER_1:
		player_color = "Черных" # Или DarkMaterial
	else:
		player_color = "Белых" # Или LightMaterial
		
	player_turn_label.text = "Ход: " + player_color
#--------------------------------------------------
# --- КОНТРОЛЛЕР: Обработчик наведения ---
func _on_cell_hovered(coords: Vector3i):	
	handle_hover_visuals(coords)	
	
# --- КОНТРОЛЛЕР: Обработчик выхода мыши ---
# Нужен, чтобы удалить призрака, когда мышь покидает последнюю активную ячейку
func _on_cell_unhovered():
	if ghost_piece:
		ghost_piece.queue_free()
		ghost_piece = null

# Функция для управления отображением полупрозрачной фишки
func handle_hover_visuals(coords: Vector3i):
	var x = coords.x
	var y = coords.y
	var z = coords.z
	
	# 1. Если ghost_piece существует, удаляем его
	if ghost_piece:
		ghost_piece.queue_free()
		ghost_piece = null
		
	# 2. Если ячейка занята, ничего не делаем
	if board_state[x][y][z] != EMPTY:
		return
		
	# 3. Создаем новую полупрозрачную фишку
	var piece = piece_scene.instantiate()
	var cell_pos = get_cell_position_from_coords(coords)
	piece.position = cell_pos
	
	# Установка полупрозрачного материала для текущего игрока
	if current_player == PLAYER_1:
		piece.get_node("MeshInstance3D").material_override = DarkAlphaMaterial
	else:
		piece.get_node("MeshInstance3D").material_override = LightAlphaMaterial
		
	add_child(piece)
	
	# 4. Сохраняем ссылку на созданный объект
	ghost_piece = piece

# --- КОНТРОЛЛЕР: Обработчик клика ---
func _on_cell_clicked(coords: Vector3i):
	var x = coords.x
	var y = coords.y
	var z = coords.z
	
	if game_over: 
		return
	
	if board_state[x][y][z] == EMPTY:
		print("Ход игрока ", current_player, " на: ", coords)
		
		# 1. Обновление модели
		board_state[x][y][z] = current_player
		
		# 2. Обновление представления (визуализация фишки)
		place_piece_visual(coords)
		
		# 3. Проверка победы
		if check_win(coords, current_player):
			print("Игрок ", current_player, " победил!")
			game_over = true
			show_game_status(current_player) # Вызываем функцию отображения
			# таймер для автоматического перезапуска
			await get_tree().create_timer(4.0).timeout
			reset_game()
			return
		
		if ghost_piece:
			ghost_piece.queue_free()
			ghost_piece = null
			
		#3.1 создание ячейки над выбранной
		if((y + 1) < board_size):
			create_cell(x, (y + 1), z)
		
		# 4. Переключение игрока
		current_player = PLAYER_2 if current_player == PLAYER_1 else PLAYER_1
		update_turn_display()
	else:
		print("Эта позиция уже занята.")
#--------------------------------------------------

# Функция для визуального размещения фишки
func place_piece_visual(coords: Vector3i):
	var piece = piece_scene.instantiate()
	
	# Установка 3D-позиции фишки (должна совпадать с позицией ячейки)
	var cell_pos = get_cell_position_from_coords(coords)
	piece.position = cell_pos
	
	# Установка цвета (материала фишки)
	if current_player == 1:
		piece.get_node("MeshInstance3D").material_override = DarkMaterial
	else:
		piece.get_node("MeshInstance3D").material_override = LightMaterial
	
	add_child(piece)
	
# Вспомогательная функция для получения 3D-позиции по логическим координатам
func get_cell_position_from_coords(coords: Vector3i) -> Vector3:
	var x = coords.x
	var y = coords.y
	var z = coords.z
	var offset = float(board_size) / 2.0
	
	var pos = Vector3.ZERO
	pos.x = x * CELL_SIZE_X - offset + CELL_SIZE_X / 2
	pos.z = z * CELL_SIZE_Z - offset + CELL_SIZE_Z / 2
	pos.y = y * CELL_SIZE_Y - offset + CELL_SIZE_Y / 2
	return pos

# Определение победителя
func check_win(coords: Vector3i, player_id: int) -> bool:
	var x = coords.x
	var y = coords.y
	var z = coords.z
	
	#массив с 13 уникальными (без обратных) векторами
	var unique_directions = [
		Vector3i(1, 0,  0), Vector3i(0, 1,  0), Vector3i(0, 0,  1),
		Vector3i(1, 1,  0), Vector3i(1, -1, 0), Vector3i(1, 0,  1),
		Vector3i(1, 0,  -1), Vector3i(0, 1,  1), Vector3i(0, 1,  -1),
		Vector3i(1, 1,  1), Vector3i(1, 1,  -1), Vector3i(1, -1, 1),
		Vector3i(-1, 1, 1)]
	
	# подсчёт по направлению
	for direction in unique_directions:
		var count = 1
		
		# в одлну сторону ->
		count += count_line_match(x, y, z, direction, player_id)
		# в другую сторону <-
		count += count_line_match(x, y, z, -direction, player_id)
		
		if count >= 4:
			return true
			
	return false

func count_line_match(start_x: int, start_y: int, start_z: int, direction: Vector3i, player_id: int) -> int:
	var count = 0
	var dx = direction.x
	var dy = direction.y
	var dz = direction.z
	
	# Максимальное расстояние, которое нужно проверить, это 3
	# (поскольку 1 фишка уже стоит, нам нужно 3 дополнительных)
	for step in range(1, 4): 
		var cx = start_x + dx * step
		var cy = start_y + dy * step
		var cz = start_z + dz * step
		
		# 1. Проверка границ доски (0 <= coord < 5)
		if cx < 0 or cx >= board_size or cy < 0 or cy >= board_size or cz < 0 or cz >= board_size:
			break
		
		# 2. Проверка фишки
		if board_state[cx][cy][cz] == player_id:
			count += 1
		else:
			# Если найдена фишка другого игрока или пустое место,
			# цепочка прерывается.
			break 
			
	return count
	
func show_game_status(winning_player: int):
	game_status_label.visible = true
	var player_name = "Черных" if winning_player == PLAYER_1 else "Белых"
	game_status_label.text = "🏆 ПОБЕДА! Игрок за " + player_name + " выиграл!"
