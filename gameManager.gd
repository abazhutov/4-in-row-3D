extends Node3D

var cell_scene = preload("res://cell.tscn")
var piece_scene = preload("res://piece.tscn") # Сцена вашей фишки

var DarkMaterial = load("res://Materials/darkMaterial.tres")
var LightMaterial = load("res://Materials/lightMaterial.tres")
var TransparentMaterial = load("res://Materials/alpa0.tres")

const cell_size = 1.0
const board_size = 5 # 5x5x5
var board_offset = float(board_size) / 2.0
var current_player = 1 # 1: Игрок 1 (Black), 2: Игрок 2/AI (White)

# --- МОДЕЛЬ ИГРЫ ---
const EMPTY = 0
const PLAYER_1 = 1
const PLAYER_2 = 2
var board_state: Array = [] # 3D-массив для хранения состояния: board_state[x][y][z]

func _ready():
	# clear_board()
	init_board_state()
	generate_board_cells()

func reset_game ():
	clear_board()
	board_state.clear()
	init_board_state()
	generate_board_cells()
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
	cell.position.x = x * cell_size - board_offset + cell_size / 2 
	cell.position.z = z * cell_size - board_offset + cell_size / 2
	cell.position.y = y * cell_size - board_offset + cell_size / 2
	# 1. Передача логических координат ячейке
	cell.set_coordinates(Vector3i(x, y, z))
	# 2. Подключение сигнала: при клике вызывается метод _on_cell_clicked
	cell.cell_clicked.connect(_on_cell_clicked)
	
	add_child(cell)

#--------------------------------------------------
# --- КОНТРОЛЛЕР: Обработчик клика ---
func _on_cell_clicked(coords: Vector3i):
	var x = coords.x
	var y = coords.y
	var z = coords.z
	
	print("x=",x,"y=",y,"z",z)
	
	if board_state[x][y][z] == EMPTY:
		print("Ход игрока ", current_player, " на: ", coords)
		
		# 1. Обновление модели
		board_state[x][y][z] = current_player
		
		# 2. Обновление представления (визуализация фишки)
		place_piece_visual(coords)
		
		# 3. Проверка победы
		if check_win(coords, current_player):
			print("Игрок ", current_player, " победил!")
			reset_game()
			return
			
		#3.1 создание ячейки над выбранной
		if((y + 1) < board_size):
			create_cell(x, (y + 1), z)
		
		# 4. Переключение игрока
		current_player = PLAYER_2 if current_player == PLAYER_1 else PLAYER_1
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
	pos.x = x * cell_size - offset + cell_size / 2
	pos.z = z * cell_size - offset + cell_size / 2
	pos.y = y * cell_size - offset + cell_size / 2
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
