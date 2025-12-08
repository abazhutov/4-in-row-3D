extends Node3D

# --- Настройки Камеры ---
const ROTATION_SPEED = 0.003 # Скорость вращения мышью
const PAN_SPEED = 0.01       # Скорость панорамирования (перетаскивания)
const ZOOM_SPEED = 0.3       # Скорость зума колесиком
const MIN_DISTANCE = -10.0     # Минимальное расстояние камеры от центра
const MAX_DISTANCE = 15.0    # Максимальное расстояние камеры от центра

var is_rotating = false
var is_panning = false
var pan_origin: Vector2
var camera_arm: Node3D # Ссылка на CameraArm
var camera_node: Camera3D # Ссылка на Camera3D

func _ready():
	# Получаем ссылки на дочерние узлы
	camera_arm = $CameraArm
	camera_node = $CameraArm/Camera3D
	
	# Делаем курсор видимым по умолчанию
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# ГЛАВНАЯ ФУНКЦИЯ ОБРАБОТКИ ВВОДА
func _input(event):
	handle_mouse_buttons(event)
	handle_scroll_wheel(event)

func _process(delta):
	# Если мы вращаем или перетаскиваем, это обрабатывается в _input (для движения мыши)
	pass

func handle_mouse_buttons(event):
	# --- ВРАЩЕНИЕ (Средняя Кнопка) ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_rotating = event.pressed
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if is_rotating else Input.MOUSE_MODE_VISIBLE)
		
		# --- ПАНОРАМИРОВАНИЕ (Правая Кнопка) ---
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_panning = event.pressed
			if is_panning:
				pan_origin = event.position # Запоминаем начальную позицию

	# --- ДВИЖЕНИЕ МЫШИ ---
	if event is InputEventMouseMotion:
		var motion = event.relative
		
		if is_rotating:
			# Вращение вокруг Y (узла CameraPivot)
			self.rotation.y -= motion.x * ROTATION_SPEED
			
			# Наклон вокруг X (узла CameraArm)
			var new_x_rot = camera_arm.rotation.x - motion.y * ROTATION_SPEED
			# Ограничиваем наклон, чтобы не перевернуть камеру
			camera_arm.rotation.x = clamp(new_x_rot, deg_to_rad(-80), deg_to_rad(-10))
			
		elif is_panning and is_panning:
			# Получаем вектор движения в мировых координатах
			var pan_vector = Vector3.ZERO
			
			# Движение вправо/влево (X)
			pan_vector += camera_node.global_transform.basis.x * -motion.x * PAN_SPEED
			
			# Движение вверх/вниз (Y)
			pan_vector += camera_node.global_transform.basis.y * motion.y * PAN_SPEED
			
			self.global_position += pan_vector
			
# --- 3. Реализация ЗУМИРОВАНИЯ ---

func handle_scroll_wheel(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-ZOOM_SPEED) # Приближаем (Z уменьшается)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(ZOOM_SPEED)  # Отдаляем (Z увеличивается)

func zoom_camera(amount):
	# Изменяем Z-позицию Camera3D относительно CameraArm
	var new_z = camera_node.position.z + amount
	
	# Ограничиваем расстояние, чтобы камера не прошла через центр
	new_z = clamp(new_z, MIN_DISTANCE, MAX_DISTANCE)
	
	camera_node.position.z = new_z
