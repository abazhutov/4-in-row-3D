extends Area3D

# Сигнал, который будет отправлен главному контроллеру при клике
signal cell_clicked(coords: Vector3i)
signal cell_hovered(coords: Vector3i)
signal cell_unhovered # Просто сигнал, без координат, для очистки

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
		
# Обработка наведения (используем встроенные сигналы Area3D)
func _on_mouse_entered():
	# Отправляем сигнал о наведении с координатами
	cell_hovered.emit(board_coords)

func _on_mouse_exited():
	# Отправляем сигнал об уходе мыши (для удаления призрака)
	cell_unhovered.emit()
