extends Node3D

var cell_scene = preload("res://cell.tscn")

const cell_size = 1.0
const board_size = 5 # 5x5x5

func generate_board_cells():
	# Генерация ячеек и их центрирование
	for x in range(board_size):
		for z in range(board_size):
			for y in range(board_size):
				var cell = cell_scene.instantiate()
				
				# Расчет позиции для центрирования
				var offset = float(board_size) / 2.0
				cell.position.x = x * cell_size - offset + cell_size / 2 
				cell.position.z = z * cell_size - offset + cell_size / 2
				cell.position.y = y * cell_size - offset + cell_size / 2
				
				add_child(cell)
