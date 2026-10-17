extends Control
## 虚拟摇杆 / Virtual Joystick
## 支持触屏拖拽和鼠标拖拽，输出归一化方向向量
## 未操作时隐藏外圈，操作时淡入显示
## 兼容手柄输入 / Compatible with gamepad input
## 支持取消：拖到下方显示红色区域，松开时取消选牌
## Supports cancel: drag to bottom to show red zone, release to cancel selection

# 摇杆参数 / Joystick parameters
const BASE_RADIUS: float = 60.0     # 底盘半径 / Base radius
const HANDLE_RADIUS: float = 20.0   # 摇杆手柄半径 / Handle radius
const DEAD_ZONE: float = 0.1        # 死区 / Dead zone threshold

# 取消区域参数 / Cancel zone parameters
const CANCEL_Y_THRESHOLD: float = 0.65  # Y 输出超过此值进入取消区域 / Y output above this enters cancel zone

# 透明度 / Opacity
const IDLE_ALPHA: float = 0.25       # 未操作时整体透明度
const ACTIVE_ALPHA: float = 1.0      # 操作时整体透明度
const FADE_DURATION: float = 0.2     # 淡入淡出时长 / Fade duration

# 状态 / State
var is_dragging: bool = false
var touch_index: int = -1
var output_vector: Vector2 = Vector2.ZERO
var in_cancel_zone: bool = false   # 是否在取消区域 / Whether in cancel zone

# 节点引用 / Node references
@onready var base_node: Control = $Base
@onready var handle_node: Control = $Handle
@onready var cancel_zone: PanelContainer = $CancelZone

# 信号 / Signals
signal joystick_input(direction: Vector2)
signal joystick_cancelled()  # 在取消区域释放时触发 / Emitted when released in cancel zone

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(BASE_RADIUS * 2, BASE_RADIUS * 2)
	size = Vector2(BASE_RADIUS * 2, BASE_RADIUS * 2)

	base_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base_node.size = Vector2(BASE_RADIUS * 2, BASE_RADIUS * 2)
	base_node.position = Vector2.ZERO

	handle_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	handle_node.size = Vector2(HANDLE_RADIUS * 2, HANDLE_RADIUS * 2)
	_reset_handle()

	# 初始状态：外圈隐藏，内球可见，取消区域隐藏
	# Initial: outer ring hidden, handle visible, cancel zone hidden
	modulate.a = 1.0
	base_node.modulate.a = 0.0
	handle_node.visible = true
	cancel_zone.visible = false
	cancel_zone.modulate.a = 0.0

	# 取消区域样式 / Cancel zone style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.2, 0.2, 0.4)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	cancel_zone.add_theme_stylebox_override("panel", style)

func _draw():
	var center = Vector2(BASE_RADIUS, BASE_RADIUS)
	draw_circle(center, base_node.size.x / 2.0, Color(0.3, 0.3, 0.3, 0.5))
	draw_arc(center, base_node.size.x / 2.0 - 1, 0, TAU, 64, Color(0.6, 0.6, 0.6, 0.6), 2.0)

func _gui_input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			if not is_dragging and _is_in_base(event.position):
				_start_drag(event.index)
				_update_handle(event.position)
		else:
			if event.index == touch_index:
				_release()

	elif event is InputEventScreenDrag:
		if is_dragging and event.index == touch_index:
			_update_handle(event.position)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not is_dragging and _is_in_base(event.position):
					_start_drag(-1)
					_update_handle(event.position)
			else:
				if is_dragging and touch_index == -1:
					_release()

	elif event is InputEventMouseMotion:
		if is_dragging and touch_index == -1:
			_update_handle(event.position)

## 检测是否在底盘范围内 / Check if position is within base
func _is_in_base(local_pos: Vector2) -> bool:
	var center = Vector2(BASE_RADIUS, BASE_RADIUS)
	return local_pos.distance_to(center) <= BASE_RADIUS

## 开始拖拽：淡入外圈 / Start drag: fade in outer ring
func _start_drag(finger_index: int):
	is_dragging = true
	touch_index = finger_index
	in_cancel_zone = false
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(base_node, "modulate:a", 1.0, FADE_DURATION)

## 更新手柄位置 / Update handle position
func _update_handle(local_pos: Vector2):
	var center = Vector2(BASE_RADIUS, BASE_RADIUS)
	var offset = local_pos - center

	if offset.length() > BASE_RADIUS:
		offset = offset.normalized() * BASE_RADIUS

	handle_node.position = center + offset - Vector2(HANDLE_RADIUS, HANDLE_RADIUS)

	output_vector = offset / BASE_RADIUS
	if output_vector.length() < DEAD_ZONE:
		output_vector = Vector2.ZERO

	# 取消区域检测 / Cancel zone detection
	var was_in_cancel = in_cancel_zone
	in_cancel_zone = output_vector.y > CANCEL_Y_THRESHOLD

	if in_cancel_zone and not was_in_cancel:
		# 进入取消区域：显示红色 / Enter cancel zone: show red
		_show_cancel_zone()
	elif not in_cancel_zone and was_in_cancel:
		# 离开取消区域：隐藏红色 / Leave cancel zone: hide red
		_hide_cancel_zone()

	handle_node.queue_redraw()
	joystick_input.emit(output_vector)

## 释放：淡出外圈，手柄回中心 / Release: fade out, handle returns to center
func _release():
	var was_in_cancel = in_cancel_zone
	is_dragging = false
	touch_index = -1
	output_vector = Vector2.ZERO
	_reset_handle()
	_hide_cancel_zone()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(base_node, "modulate:a", 0.0, FADE_DURATION)
	joystick_input.emit(output_vector)

	# 如果在取消区域释放，发出取消信号 / If released in cancel zone, emit cancel signal
	if was_in_cancel:
		in_cancel_zone = false
		joystick_cancelled.emit()

## 显示取消区域 / Show cancel zone
func _show_cancel_zone():
	cancel_zone.visible = true
	var tween = create_tween()
	tween.tween_property(cancel_zone, "modulate:a", 1.0, 0.15)

## 隐藏取消区域 / Hide cancel zone
func _hide_cancel_zone():
	if cancel_zone.modulate.a > 0.0:
		var tween = create_tween()
		tween.tween_property(cancel_zone, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): cancel_zone.visible = false)

## 重置手柄到中心 / Reset handle to center
func _reset_handle():
	handle_node.position = Vector2(
		BASE_RADIUS - HANDLE_RADIUS,
		BASE_RADIUS - HANDLE_RADIUS
	)

## 获取输出向量 / Get output vector
func get_output() -> Vector2:
	return output_vector

## 是否正在拖拽 / Is currently being dragged
func is_active() -> bool:
	return is_dragging

## 是否在取消区域 / Is in cancel zone
func is_in_cancel_zone() -> bool:
	return in_cancel_zone
