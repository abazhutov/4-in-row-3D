extends Node3D

var cell_scene = preload("res://cell.tscn")
var piece_scene = preload("res://piece.tscn") # Сцена вашей фишки

var DarkMaterial = load("res://Materials/darkMaterial.tres")
var LightMaterial = load("res://Materials/lightMaterial.tres")

const cell_size = 1.0
const board_size = 5 # 5x5x5
var current_player = 1 # 1: Игрок 1 (Black), 2: Игрок 2/AI (White)

# --- МОДЕЛЬ ИГРЫ ---
const EMPTY = 0
const PLAYER_1 = 1
const PLAYER_2 = 2
var board_state: Array = [] # 3D-массив для хранения состояния: board_state[x][y][z]

func _ready():
	# Инициализация 3D-массива [5][5][5]
	for x in range(board_size):
		board_state.append([])
		for y in range(board_size):
			board_state[x].append([])
			for z in range(board_size):
				board_state[x][y].append(EMPTY) # Каждая ячейка изначально пуста

	generate_board_cells()

func generate_board_cells():
	# Генерация ячеек и их центрирование
	for x in range(board_size):
		for z in range(board_size):
			for y in range(board_size):
				var cell = cell_scene.instantiate()
				
				# Расчет позиции для центрирования
				var offset = float(board_size) / 2.0
				cell.position.x = x * cell_size - offset + cell_size / 2 # Добавляем 0.5 для центрирования 1x1 меша
				cell.position.z = z * cell_size - offset + cell_size / 2
				cell.position.y = y * cell_size - offset + cell_size / 2
				
				# 1. Передача логических координат ячейке
				cell.set_coordinates(Vector3i(x, y, z))
				
				# 2. Подключение сигнала: при клике вызывается метод _on_cell_clicked
				cell.cell_clicked.connect(_on_cell_clicked)
				
				add_child(cell)

# --- КОНТРОЛЛЕР: Обработчик клика ---
func _on_cell_clicked(coords: Vector3i):
	var x = coords.x
	var y = coords.y
	var z = coords.z
	
	if board_state[x][y][z] == EMPTY:
		print("Ход игрока ", current_player, " на: ", coords)
		
		# 1. Обновление модели
		board_state[x][y][z] = current_player
		
		# 2. Обновление представления (визуализация фишки)
		place_piece_visual(coords)
		
		# 3. Проверка победы (пока не реализовано)
		# if check_win(coords): 
		#     print("Игрок ", current_player, " победил!")
		#     return
		
		# 4. Переключение игрока
		current_player = PLAYER_2 if current_player == PLAYER_1 else PLAYER_1
	else:
		print("Эта позиция уже занята.")

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
