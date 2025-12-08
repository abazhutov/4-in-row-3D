# --- КОНСТАНТЫ ИГРЫ ---
const EMPTY = 0
const PLAYER_1 = 1
const PLAYER_2 = 2

# Размер доски
var board_size: int

# 3D-массив для хранения состояния
var board_state: Array = [] 

# --- ИНИЦИАЛИЗАЦИЯ ---
func init(size: int):
	board_size = size
	init_board_state()

func init_board_state():
	# Инициализация 3D-массива [5][5][5]
	board_state.clear()
	for x in range(board_size):
		board_state.append([])
		for y in range(board_size):
			board_state[x].append([])
			for z in range(board_size):
				board_state[x][y].append(EMPTY)

# --- ПРОВЕРКА ПОБЕДЫ ---
func check_win(coords: Vector3i, player_id: int) -> bool:
	var x = coords.x
	var y = coords.y
	var z = coords.z
	
	var unique_directions = [
		Vector3i(1, 0, 0), Vector3i(0, 1,  0), Vector3i(0, 0, 1),
		Vector3i(1, 1, 0), Vector3i(1, -1, 0), Vector3i(1, 0, 1),
		Vector3i(1, 0, -1), Vector3i(0, 1, 1), Vector3i(0, 1, -1),
		Vector3i(1, 1, 1), Vector3i(1, 1, -1), Vector3i(1, -1, 1),
		Vector3i(-1, 1, 1)]
	
	for direction in unique_directions:
		var count = 1
		count += count_line_match(x, y, z, direction, player_id)
		count += count_line_match(x, y, z, -direction, player_id)
		
		if count >= 4:
			return true
			
	return false

# Подсчёт кол-во фишек по вектору
func count_line_match(start_x: int, start_y: int, start_z: int, direction: Vector3i, player_id: int) -> int:
	var count = 0
	var dx = direction.x
	var dy = direction.y
	var dz = direction.z
	
	for step in range(1, 4):
		var cx = start_x + dx * step
		var cy = start_y + dy * step
		var cz = start_z + dz * step
		
		# Проверка границ доски 
		if cx < 0 or cx >= board_size or cy < 0 or cy >= board_size or cz < 0 or cz >= board_size:
			break
		
		# Проверка фишки
		if board_state[cx][cy][cz] == player_id:
			count += 1
		else:
			break
			
	return count
