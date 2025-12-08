extends Node3D

const BoardModel = preload("res://Scripts/boardModel.gd")
const GameView = preload("res://Scripts/gameView.gd")

var model = BoardModel.new()
var view = GameView.new()

# --- ПЕРЕМЕННЫЕ ИГРЫ И КОНСТАНТЫ ---
const CELL_SIZE_X = 1.0
const CELL_SIZE_Z = 1.0
const CELL_SIZE_Y = 0.5
const board_size = 5
const board_offset = float(board_size) / 2.0

const PLAYER_DROW = 0
const PLAYER_1 = 1
const PLAYER_2 = 2

@onready var player_turn_label: Label = $"CanvasLayer/ControlPlayerTurn/LabelPlayerTurn"
@onready var game_status_label: Label = $"CanvasLayer/ControlGameStatus/LabelGameStatus"
@onready var base_plane: Node3D = $Plane

var current_player = PLAYER_1
var game_over = false
var cnt_move = 0

# --- ИНИЦИАЛИЗАЦИЯ ---
func _ready():
	# Конфигурация для View
	var config = {
		CELL_SIZE_X = CELL_SIZE_X, CELL_SIZE_Y = CELL_SIZE_Y, CELL_SIZE_Z = CELL_SIZE_Z,
		board_size = board_size, board_offset = board_offset,
		player_turn_label = player_turn_label, game_status_label = game_status_label
	}
	
	# Инициализация Модели и Представления
	model.init(board_size)
	view.init(self, config) # Передаем ссылку на себя (корневой узел) и конфигурацию
	
	reset_game()

func reset_game():
	base_plane.position.y = - board_offset
	
	cnt_move = 0
	game_over = false
	
	view.hide_game_status()
	view.clear_ghost_piece()
	view.clear_board()
	model.init_board_state()
	
	# Создаем ячейки, передавая методы-обработчики из Controller
	view.generate_board_cells(
		_on_cell_clicked.bind(), 
		_on_cell_hovered.bind(), 
		_on_cell_unhovered.bind()
	)

	current_player = PLAYER_1
	view.update_turn_display(current_player)
	print("Игра перезапущена. Ход игрока ", current_player)

# --- КОНТРОЛЛЕР: ОБРАБОТКА ВВОДА ---
func _on_cell_hovered(coords: Vector3i):	
	if game_over: return
	
	var x = coords.x
	var y = coords.y
	var z = coords.z
	
	var is_empty = model.board_state[x][y][z] == model.EMPTY
	view.handle_hover_visuals(coords, current_player, is_empty)	
	
func _on_cell_unhovered():
	if game_over: return
	view.clear_ghost_piece()

func _on_cell_clicked(coords: Vector3i):
	if game_over:
		return
		
	var x = coords.x
	var y = coords.y
	var z = coords.z
	
	if model.board_state[x][y][z] == model.EMPTY:
		
		# 1. Обновление Модели
		model.board_state[x][y][z] = current_player
		cnt_move += 1
		
		# 2. Обновление Представления
		view.place_piece_visual(coords, current_player)
		view.clear_ghost_piece()
			
		# 3. Проверка Победы (Model)
		if model.check_win(coords, current_player):
			game_over = true
			view.show_game_status(current_player, "WIN")
			await get_tree().create_timer(4.0).timeout
			reset_game()
			return
			
		# Проверка Ничьей (Logic)
		if cnt_move == board_size * board_size * board_size:
			game_over = true
			view.show_game_status(PLAYER_DROW, "DRAW")
			await get_tree().create_timer(4.0).timeout
			reset_game()
			return
		
		# 4. Создание следующей ячейки (View)
		if((y + 1) < board_size):
			# Используем метод View для создания ячейки
			view.create_cell(
				x, y + 1, z, 
				_on_cell_clicked.bind(), 
				_on_cell_hovered.bind(), 
				_on_cell_unhovered.bind()
			)
		
		# 5. Переключение Игрока (Controller)
		current_player = PLAYER_2 if current_player == PLAYER_1 else PLAYER_1
		view.update_turn_display(current_player)
	else:
		print("Эта позиция уже занята.")
