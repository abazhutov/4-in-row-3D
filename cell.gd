extends Area3D

# Сигнал, который будет отправлен главному контроллеру при клике
signal cell_clicked(coords: Vector3i)

# Координаты ячейки в логическом массиве [x][y][z]
var board_coords: Vector3i

# Метод для установки логических координат (вызывается при создании ячейки)
func set_coordinates(coords: Vector3i):
	board_coords = coords

# Обработка события ввода (срабатывает, если луч мыши попадает в CollisionShapeD)
func _input_event(camera, event, position, normal, shape_idx):
	# Проверяем, что это левая кнопка мыши и она была нажата
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Если нажатие подтверждено, отправляем сигнал, передавая свои координаты
		cell_clicked.emit(board_coords)
