extends Control
## 牌扇管理器 / Card Fan Manager
## 管理多张卡牌的扇形排列、悬停上浮和邻牌避让
## Manages fan-shaped arrangement, hover float, and neighbor avoidance for cards
## 支持鼠标、触屏、虚拟摇杆和手柄摇杆选牌
## Supports mouse, touch, virtual joystick, and gamepad for card selection
## 支持发出卡牌（双击/上滑/摇杆释放）和长按拖拽排序
## Supports playing cards (double-click / swipe-up / joystick release) and long-press drag reordering
## 新牌从上方飞入牌扇 / New cards fly in from above
##
## 使用方式：实例化此场景，用 add_card() / remove_card() 管理卡牌
## Usage: Instantiate this scene and use add_card() / remove_card() to manage cards
## 连接 card_played 信号处理出牌事件 / Connect card_played signal to handle play events
## 设 show_debug_buttons = true 开启调试按钮 / Set show_debug_buttons = true for debug buttons

# ========== 导出设置 / Export Settings ==========
## 卡牌场景路径（默认内置卡牌场景）/ Path to the card scene
@export var card_scene_path: String = "res://addons/card_fan/src/card.tscn"
## 显示调试加牌/减牌按钮 / Show debug add/remove buttons
@export var show_debug_buttons: bool = false:
	set(value):
		show_debug_buttons = value
		if is_inside_tree() and has_node("DebugButtons"):
			$DebugButtons.visible = value
## 启用虚拟摇杆 / Enable virtual joystick
@export var joystick_enabled: bool = true

@export var jokers: bool = false

# ========== 扇形排列参数 / Fan Arrangement Parameters ==========
## 卡牌尺寸 / Card dimensions
@export_group("Fan Layout", "fan_")
@export var fan_card_width: float = 80.0
@export var fan_card_height: float = 120.0
## 扇形半径（越大弧线越平缓）/ Fan radius (larger = flatter arc)
@export var fan_radius: float = 600.0
## 牌扇最大总展开角度（度）/ Max total fan spread angle (degrees)
@export var fan_max_angle: float = 50.0
## 少牌时每张牌的角度间距（不要太散）/ Angle step when few cards
@export var fan_max_angle_step: float = 5.0
## 多牌时最小角度间距（允许更紧凑）/ Min angle step when many cards
@export var fan_min_angle_step: float = 0.5
## 排列动画时长 / Arrange animation duration
@export var fan_arrange_duration: float = 0.3
## 新牌入场动画时长 / New card enter animation duration
@export var fan_enter_duration: float = 0.4

## 悬停 & 避让参数 / Hover & avoidance parameters
@export_group("Hover", "hover_")
## 悬停时沿法线上浮距离 / Hover float distance along normal
@export var hover_offset: float = 30.0
## 邻牌避让旋转角度（度）/ Neighbor avoidance rotation angle (degrees)
@export var hover_avoid_angle: float = 3.0
## 悬停/避让动画时长 / Hover animation duration
@export var hover_duration: float = 0.12

## 摇杆参数 / Joystick parameters
@export_group("Joystick", "joy_")
## 摇杆闲置多久后取消选牌 / Joystick inactive timeout
@export var joy_inactive_timeout: float = 1.5
## 摇杆最低激活时间（秒），低于此值释放不会发牌，防止误触
## Min joystick active time (seconds); release before this won't play card, prevents accidental play
@export var joy_min_active_time: float = 0.3

## 发出卡牌参数 / Play card parameters
@export_group("Play Card", "play_")
## 双击最大间隔（秒）/ Double-click max interval (seconds)
@export var play_double_click_interval: float = 0.35
## 最小滑动距离（px）/ Min swipe distance (px)
@export var play_swipe_min_distance: float = 40.0
## 上滑方向容差（度）/ Swipe-up direction tolerance (degrees)
@export var play_swipe_up_tolerance: float = 40.0
## 发出动画时长（秒）/ Play animation duration (seconds)
@export var play_fly_duration: float = 0.35
## 发出飞行距离（px）/ Play fly distance (px)
@export var play_fly_distance: float = 500.0

## 拖拽排序参数 / Drag reorder parameters
@export_group("Drag Reorder", "drag_")
## 长按触发时间（秒）/ Long press trigger time (seconds)
@export var drag_long_press_duration: float = 0.45
## 长按最大移动距离（px）/ Long press max move distance (px)
@export var drag_long_press_move_threshold: float = 12.0
## 拖拽时空位宽度倍率 / Gap width multiplier during drag
@export var drag_gap_factor: float = 0.7

## 日志 / Logging
@export_group("Debug", "debug_")
## 启用调试日志（打印卡牌操作到控制台）/ Enable debug logging
@export var debug_logging: bool = false

# 节点引用 / Node references
@onready var cards_container: Control = $CardsContainer
@onready var add_card_btn: Button = $DebugButtons/AddCardBtn
@onready var remove_card_btn: Button = $DebugButtons/RemoveCardBtn
@onready var card_count_label: Label = $DebugButtons/CardCountLabel
@onready var joystick: Control = $Joystick

var joker_int = 0

var cards_in_deck = []

# 光标小点（代码中创建）/ Cursor dot (created in code)
var cursor_dot: Control = null

# 卡牌数组 / Card array
var cards: Array = []

# 信号 / Signals
signal card_played(card)  # 发出卡牌时触发（动画开始前）/ Emitted when a card is played
signal card_clicked(card)  # 单击时触发 / Emitted on single click

# ========== 内部状态 / Internal State ==========
var hovered_card: Control = null
var card_tweens: Dictionary = {}       # card -> Tween
var card_base_angles: Dictionary = {}  # card -> 基础角度（度）/ base angle (degrees)

# 摇杆状态 / Joystick state
var joystick_active: bool = false
var gamepad_vector: Vector2 = Vector2.ZERO
var joystick_inactive_timer: float = 0.0
var joystick_play_candidate: Control = null   # 摇杆悬停的卡牌（发出候选）/ Joystick hover candidate
var joystick_prev_had_card: bool = false       # 上帧是否有悬停卡牌 / Had card last frame
var joystick_active_start_time: float = 0.0    # 摇杆激活起始时间 / Joystick activation start time

# 按压/手势追踪 / Press/gesture tracking
var is_pressing: bool = false
var press_start_pos: Vector2 = Vector2.ZERO    # 按下起始全局位置 / Press start global position
var press_start_time: float = 0.0              # 按下起始时间 / Press start time
var press_card: Control = null                 # 按下时的卡牌 / Card at press
var current_press_pos: Vector2 = Vector2.ZERO  # 当前按压位置 / Current press position
var long_press_triggered: bool = false         # 长按已触发 / Long press triggered

# 鼠标双击状态 / Mouse double-click state
var last_click_time: float = 0.0
var last_click_card: Control = null
var click_pending_emit: bool = false

# 触屏状态 / Touch state
var touch_active: bool = false
var touch_finger_index: int = -1
var touch_start_global_pos: Vector2 = Vector2.ZERO

# 拖拽排序状态 / Drag reorder state
var is_dragging: bool = false
var dragging_card: Control = null
var drag_original_index: int = -1
var drag_insert_index: int = -1
var drag_offset: Vector2 = Vector2.ZERO

# 发出动画状态 / Play animation state
var is_playing_card: bool = false

# 扇形中心（相对于 CardsContainer 局部坐标）/ Fan center (relative to CardsContainer)
var fan_center: Vector2 = Vector2.ZERO

func _ready():
	if jokers:
		joker_int = 2
	add_card_btn.pressed.connect(_on_add_card)
	remove_card_btn.pressed.connect(_on_remove_card)
	_update_card_count()
	cards_container.position = Vector2.ZERO
	cards_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 创建光标小点 / Create cursor dot
	_create_cursor_dot()

	# 定位摇杆 / Position joystick
	if joystick_enabled:
		_position_joystick()
		joystick.show()
		joystick.joystick_cancelled.connect(_on_joystick_cancelled)
	else:
		joystick.hide()

	# 调试按钮可见性 / Debug buttons visibility
	$DebugButtons.visible = show_debug_buttons

## 创建光标小点并添加到 CardsContainer / Create cursor dot and add to CardsContainer
func _create_cursor_dot():
	var dot_script = load("res://addons/card_fan/src/cursor_dot.gd")
	cursor_dot = Control.new()
	cursor_dot.set_script(dot_script)
	cards_container.add_child(cursor_dot)

## 将摇杆定位到屏幕右侧中间偏下 / Position joystick to bottom-right of screen
func _position_joystick():
	var viewport_size = get_viewport_rect().size
	var joystick_size = Vector2(120, 120)
	var target_global = Vector2(
		viewport_size.x - joystick_size.x - 30,
		viewport_size.y / 2.0 + 50
	)
	joystick.position = target_global - global_position

func _process(delta: float):
	_update_joystick_dot(delta)
	_check_long_press()
	_check_pending_click()

## 获取当前时间（秒）/ Get current time in seconds
func _get_now() -> float:
	return Time.get_ticks_msec() / 1000.0

## 重置交互状态 / Reset interaction state
func _reset_interaction_state():
	is_pressing = false
	long_press_triggered = false
	press_card = null
	click_pending_emit = false
	last_click_card = null

## 调试日志 / Debug log
func _log(msg: String):
	if debug_logging:
		print(msg)

# =============================================
#  发出卡牌（三种方式共用的出牌逻辑）
#  Play Card (shared logic for all input methods)
# =============================================

## 发出一张卡牌（飞出动画）/ Play a card (fly-out animation)
func play_card(card: Control):
	if is_playing_card or card == null:
		return
	if not cards.has(card):
		return
	is_playing_card = true

	# 清除悬停 / Clear hover
	if hovered_card == card:
		card.set_hovered(false)
		hovered_card = null

	# 发出信号（外部可在此读取牌数据）/ Emit signal
	card_played.emit(card)
	_log("Played: " + card.get_card_name())

	# 从数组移除（但不 queue_free，等动画完成）/ Remove from array (don't free yet)
	cards.erase(card)
	card_base_angles.erase(card)

	# 剩余牌填补空位 / Remaining cards fill the gap
	_arrange_cards()
	_update_card_count()

	# 启动飞出动画 / Start fly-out animation
	_animate_card_play(card)

	# 重置交互状态 / Reset interaction state
	_reset_interaction_state()

## 飞出动画 / Fly-out animation
func _animate_card_play(card: Control):
	if card_tweens.has(card) and card_tweens[card] and card_tweens[card].is_valid():
		card_tweens[card].kill()
	card_tweens.erase(card)

	# 目标位置：沿卡牌当前朝向往上飞 / Target: fly up along card's current facing
	var fly_direction = Vector2(0, -play_fly_distance).rotated(card.rotation)
	var target_pos = card.position + fly_direction

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(true)
	tween.tween_property(card, "position", target_pos, play_fly_duration)
	tween.tween_property(card, "modulate:a", 0.0, play_fly_duration)
	tween.tween_property(card, "scale", Vector2(0.8, 0.8), play_fly_duration)
	tween.finished.connect(_on_play_animation_finished.bind(card))

## 飞出动画完成回调 / Fly-out animation finished callback
func _on_play_animation_finished(card: Control):
	if is_instance_valid(card):
		card.queue_free()
	is_playing_card = false

# =============================================
#  摇杆选牌逻辑（位置映射：摇杆位置直接对应牌扇区域）
#  Joystick Card Selection (position maps to fan area)
# =============================================

## 每帧更新摇杆选牌 / Update joystick selection each frame
func _update_joystick_dot(_delta: float):
	if not joystick_enabled:
		return

	# 合并虚拟摇杆和手柄输入 / Merge virtual joystick and gamepad input
	var virt = joystick.get_output() if joystick else Vector2.ZERO
	var combined = virt + gamepad_vector
	if combined.length() > 1.0:
		combined = combined.normalized()

	var input_strength = combined.length()

	if input_strength > 0.1:
		# 摇杆有输入 → 位置映射 / Joystick has input → position mapping
		joystick_active = true
		joystick_inactive_timer = 0.0
		# 记录激活起始时间 / Record activation start time
		if joystick_active_start_time == 0.0:
			joystick_active_start_time = _get_now()

		if cards.is_empty():
			return

		if is_dragging or touch_active or is_playing_card:
			return

		_update_fan_center()

		var angle_step = _calculate_angle_step()
		var count = cards.size()
		var total_fan = angle_step * max(0, count - 1)
		var half_fan = total_fan / 2.0

		# X 映射角度，稍微放大范围让边缘牌更容易选到
		# Map X to angle, slightly enlarge range for edge cards
		var mapped_angle = combined.x * (half_fan + 2.0)
		var mapped_rad = deg_to_rad(mapped_angle)

		# 光标在弧线上的位置 / Cursor position on the arc
		var dot_arc = Vector2(
			fan_center.x + sin(mapped_rad) * fan_radius,
			fan_center.y - cos(mapped_rad) * fan_radius
		)
		dot_arc += Vector2(0, combined.y * 40.0).rotated(mapped_rad)

		cursor_dot.position = dot_arc - Vector2(cursor_dot.DOT_RADIUS, cursor_dot.DOT_RADIUS)

		if not cursor_dot.visible:
			cursor_dot.show_dot()

		# 用光标位置做碰撞检测 / Use cursor position for hit detection
		var dot_center = cursor_dot.get_center_position()
		var card = _get_card_at_pos(dot_center)

		# 如果光标没直接命中，用角度找最近的牌
		# If cursor didn't hit directly, find nearest card by angle
		if not card:
			var best_dist: float = INF
			for c in cards:
				var c_angle = card_base_angles.get(c, 0.0)
				var dist = abs(c_angle - mapped_angle)
				if dist < best_dist:
					best_dist = dist
					card = c

		if card != hovered_card:
			if hovered_card:
				hovered_card.set_hovered(false)
			hovered_card = card
			if hovered_card:
				hovered_card.set_hovered(true)
			_update_hover_positions()

		# 记录摇杆发牌候选 / Record joystick play candidate
		joystick_play_candidate = hovered_card
		joystick_prev_had_card = (hovered_card != null)
	else:
		# 摇杆无输入 / Joystick has no input
		if joystick_active:
			# 首帧过渡：仅当摇杆真正释放时才发牌（手指/鼠标已离开摇杆）
			# First frame: only play card when joystick is truly released (finger/mouse left)
			if joystick_inactive_timer == 0.0:
				# 检查摇杆是否真的被释放（不是输出暂时降为零）
				# Check if joystick is truly released (not just output temporarily at zero)
				var truly_released = true
				if joystick and joystick.is_active():
					truly_released = false
				if truly_released:
					# 最低激活时间保护
					# Min active time guard
					var active_duration = _get_now() - joystick_active_start_time if joystick_active_start_time > 0.0 else 0.0
					if active_duration >= joy_min_active_time:
						if joystick_prev_had_card and joystick_play_candidate != null:
							if cards.has(joystick_play_candidate) and not is_dragging and not touch_active and not is_playing_card:
								play_card(joystick_play_candidate)
				joystick_prev_had_card = false
				joystick_play_candidate = null
				joystick_active_start_time = 0.0

			joystick_inactive_timer += _delta
			if joystick_inactive_timer >= joy_inactive_timeout:
				joystick_active = false
				cursor_dot.hide_dot()
				_clear_joystick_hover()

## 清除摇杆悬停状态 / Clear joystick hover state
func _clear_joystick_hover():
	if hovered_card:
		hovered_card.set_hovered(false)
		hovered_card = null
		_update_hover_positions()

## 摇杆取消选牌回调 / Joystick cancel selection callback
func _on_joystick_cancelled():
	joystick_active = false
	joystick_prev_had_card = false
	joystick_play_candidate = null
	joystick_active_start_time = 0.0
	joystick_inactive_timer = 0.0
	cursor_dot.hide_dot()
	_clear_joystick_hover()
	_log("Joystick selection cancelled")

# =============================================
#  手势检测辅助 / Gesture Detection
# =============================================

## 检测是否为上滑手势 / Check if gesture is swipe-up
func _is_swipe_up(start_pos: Vector2, end_pos: Vector2) -> bool:
	var delta = end_pos - start_pos
	if delta.length() < play_swipe_min_distance:
		return false
	# 在屏幕坐标中，上方为 -Y，所以上滑角度接近 -90 度
	# In screen coords, up is -Y, so swipe-up angle is near -90 degrees
	var angle = rad_to_deg(atan2(delta.y, delta.x))
	return abs(angle - (-90.0)) <= play_swipe_up_tolerance

## 每帧检测长按 / Check long press each frame
func _check_long_press():
	if not is_pressing or long_press_triggered or is_dragging or is_playing_card:
		return
	if press_card == null:
		return
	if not cards.has(press_card):
		is_pressing = false
		return
	# 检查是否移动过远 / Check if moved too far
	var dist = current_press_pos.distance_to(press_start_pos)
	if dist > drag_long_press_move_threshold:
		return
	# 检查时间 / Check time
	if _get_now() - press_start_time >= drag_long_press_duration:
		long_press_triggered = true
		_start_drag(press_card, current_press_pos)
		# 取消双击等待 / Cancel double-click wait
		click_pending_emit = false
		last_click_card = null

## 每帧检测待确认的单击（双击超时）/ Check pending click (double-click timeout)
func _check_pending_click():
	if not click_pending_emit:
		return
	if _get_now() - last_click_time > play_double_click_interval:
		# 双击窗口过期，是单击 / Double-click window expired, it's a single click
		if last_click_card and is_instance_valid(last_click_card) and cards.has(last_click_card):
			last_click_card.card_clicked.emit(last_click_card)
			card_clicked.emit(last_click_card)
			_log("Card Clicked: " + last_click_card.get_card_name())
		click_pending_emit = false
		last_click_card = null

# =============================================
#  鼠标/触屏/手柄输入 / Mouse/Touch/Gamepad Input
# =============================================

## 检查触摸位置是否在摇杆区域内 / Check if touch position is on joystick area
func _is_touch_on_joystick(touch_pos: Vector2) -> bool:
	if not joystick or not joystick.visible:
		return false
	var joy_rect = Rect2(joystick.global_position, joystick.size)
	return joy_rect.has_point(touch_pos)

func _input(event):
	# 发出动画中锁定所有输入 / Lock all input during play animation
	if is_playing_card:
		return
	if cards.is_empty():
		return

	# 触屏事件（最高优先）/ Touch events (highest priority)
	if event is InputEventScreenTouch:
		# 如果触摸在摇杆区域，跳过让摇杆处理
		# If touch is on joystick area, skip to let joystick handle it
		if joystick_enabled and joystick and _is_touch_on_joystick(event.position):
			return
		_handle_screen_touch(event)
		return

	if event is InputEventScreenDrag:
		# 拖拽事件也要检查是否属于摇杆
		# Drag events also need to check if they belong to joystick
		if joystick_enabled and joystick and touch_finger_index == -1 and _is_touch_on_joystick(event.position):
			return
		_handle_screen_drag(event)
		return

	# 手柄（独立于触屏，始终处理）/ Gamepad (independent of touch)
	if event is InputEventJoypadMotion:
		_handle_gamepad_motion(event)
		return

	if event is InputEventJoypadButton:
		if event.pressed and event.button_index == JOY_BUTTON_A:
			if joystick_active and hovered_card:
				hovered_card.card_clicked.emit(hovered_card)
				card_clicked.emit(hovered_card)
				_log("Card Selected By Joystick: " + hovered_card.get_card_name())
		return

	# 鼠标事件（触屏活跃时忽略模拟鼠标）/ Mouse events (ignore when touch is active)
	if touch_active:
		return

	if event is InputEventMouseMotion:
		if joystick_active:
			return
		if joystick and joystick.is_active():
			return
		if is_dragging:
			_update_drag(event.global_position)
			return
		_handle_mouse_move(event.global_position)
		# 更新当前按压位置（长按检测用）/ Update press position (for long press)
		if is_pressing:
			current_press_pos = event.global_position

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_mouse_press(event.global_position)
		else:
			_handle_mouse_release(event.global_position)

# =============================================
#  鼠标事件处理 / Mouse Event Handlers
# =============================================

## 鼠标按下 / Mouse press
func _handle_mouse_press(global_pos: Vector2):
	if is_dragging:
		return
	var local_pos = global_pos - cards_container.global_position
	var card = _get_card_at_pos(local_pos)

	is_pressing = true
	press_start_pos = global_pos
	current_press_pos = global_pos
	press_start_time = _get_now()
	press_card = card
	long_press_triggered = false

## 鼠标释放 / Mouse release
func _handle_mouse_release(global_pos: Vector2):
	# 拖拽结束 / End drag
	if is_dragging:
		_end_drag()
		is_pressing = false
		return

	is_pressing = false

	# 长按触发过 → 已经是拖拽，不处理点击 / Long press triggered, skip click
	if long_press_triggered:
		long_press_triggered = false
		return

	# 按下时没有卡牌 / No card at press
	if press_card == null:
		return

	# 卡牌已不在牌组中 / Card no longer in fan
	if not cards.has(press_card):
		press_card = null
		return

	# 移动过远 → 不算点击 / Moved too far, not a click
	if global_pos.distance_to(press_start_pos) > drag_long_press_move_threshold:
		press_card = null
		return

	# 双击检测 / Double-click detection
	var now = _get_now()
	if last_click_card == press_card and now - last_click_time < play_double_click_interval:
		# 双击确认 → 发出卡牌 / Double-click confirmed → play card
		click_pending_emit = false
		last_click_card = null
		play_card(press_card)
		press_card = null
		return

	# 第一次点击，等待双击 / First click, wait for double-click
	last_click_card = press_card
	last_click_time = now
	click_pending_emit = true
	press_card = null

# =============================================
#  触屏事件处理 / Touch Event Handlers
# =============================================

## 触屏按下/释放 / Touch press/release
func _handle_screen_touch(event: InputEventScreenTouch):
	if event.pressed:
		# 已有手指在追踪 / Already tracking a finger
		if touch_active and event.index != touch_finger_index:
			return
		touch_active = true
		touch_finger_index = event.index
		touch_start_global_pos = event.position

		# 记录按压状态 / Record press state
		is_pressing = true
		press_start_pos = event.position
		current_press_pos = event.position
		press_start_time = _get_now()
		long_press_triggered = false

		# 命中检测 / Hit detection
		var local_pos = event.position - cards_container.global_position
		press_card = _get_card_at_pos(local_pos)

		# 立即更新悬停 / Update hover immediately
		_handle_mouse_move(event.position)
	else:
		# 释放 / Release
		if event.index != touch_finger_index:
			return

		if is_dragging:
			_end_drag()
		elif not long_press_triggered:
			# 检测上滑 / Check swipe-up
			if press_card and cards.has(press_card):
				if _is_swipe_up(touch_start_global_pos, event.position):
					play_card(press_card)
				elif event.position.distance_to(touch_start_global_pos) <= drag_long_press_move_threshold:
					# 短距离 → 当作点击 / Short distance → treat as click
					press_card.card_clicked.emit(press_card)
					card_clicked.emit(press_card)
					_log("触屏点击卡牌: " + press_card.get_card_name())

		# 重置触屏状态 / Reset touch state
		touch_active = false
		touch_finger_index = -1
		is_pressing = false
		long_press_triggered = false
		press_card = null

		# 清除悬停（手指离开屏幕）/ Clear hover (finger left screen)
		if hovered_card:
			hovered_card.set_hovered(false)
			hovered_card = null
			_update_hover_positions()

## 触屏拖动 / Touch drag
func _handle_screen_drag(event: InputEventScreenDrag):
	if event.index != touch_finger_index:
		return

	if is_dragging:
		_update_drag(event.position)
		return

	# 更新当前按压位置 / Update current press position
	current_press_pos = event.position

	# 更新悬停 / Update hover
	_handle_mouse_move(event.position)

## 处理手柄摇杆输入 / Handle gamepad joystick input
func _handle_gamepad_motion(event: InputEventJoypadMotion):
	if event.axis == JOY_AXIS_LEFT_X:
		gamepad_vector.x = event.axis_value
	elif event.axis == JOY_AXIS_LEFT_Y:
		gamepad_vector.y = event.axis_value
	if gamepad_vector.length() < 0.15:
		gamepad_vector = Vector2.ZERO

## 处理鼠标移动（悬停检测）/ Handle mouse move (hover detection)
## 鼠标快移时直接命中可能失败，用角度兜底找最近的牌
## When mouse moves fast, point hit-test may miss; fall back to nearest card by angle
func _handle_mouse_move(global_pos: Vector2):
	if is_dragging:
		return
	var local_pos = global_pos - cards_container.global_position
	var card = _get_card_at_pos(local_pos)
	# 角度兜底：直接命中失败时，按鼠标相对于扇形中心的角度找最近的牌
	# Angle fallback: if direct hit fails, find nearest card by angle from fan center
	if not card and not cards.is_empty():
		_update_fan_center()
		var dx = local_pos.x - fan_center.x
		var dy = -(local_pos.y - fan_center.y)
		var mouse_angle = rad_to_deg(atan2(dx, dy))
		var mouse_dist = Vector2(dx, -(local_pos.y - fan_center.y)).length()
		# 鼠标必须在扇形弧线附近才兜底（距离弧线不超过卡牌对角线长度）
		# Only fallback if mouse is near the arc (within card diagonal distance)
		var max_fallback_dist = fan_radius * 0.3 + max(fan_card_width, fan_card_height)
		if mouse_dist > fan_radius + max_fallback_dist or mouse_dist < fan_radius - max_fallback_dist:
			card = null
		else:
			var best_dist: float = INF
			for c in cards:
				var c_angle = card_base_angles.get(c, 0.0)
				var dist = abs(c_angle - mouse_angle)
				if dist < best_dist:
					best_dist = dist
					card = c
			# 角度也不能偏离太远 / Angle also must not be too far
			if card:
				var c_angle = card_base_angles.get(card, 0.0)
				if abs(mouse_angle - c_angle) > fan_max_angle * 0.7:
					card = null
	if card == hovered_card:
		return
	if hovered_card:
		hovered_card.set_hovered(false)
	hovered_card = card
	if hovered_card:
		hovered_card.set_hovered(true)
	_update_hover_positions()

## 根据坐标判断在哪张牌上（从右到左，右牌覆盖左牌）
## Hit test: which card is at position (right to left, right card on top)
func _get_card_at_pos(local_pos: Vector2) -> Control:
	for i in range(cards.size() - 1, -1, -1):
		var card = cards[i]
		if card == dragging_card:
			continue  # 拖拽中的牌不参与命中检测 / Skip dragging card
		var base_angle_deg = card_base_angles.get(card, 0.0)
		var base_rad = deg_to_rad(base_angle_deg)
		var arc_pos = Vector2(
			fan_center.x + sin(base_rad) * fan_radius,
			fan_center.y - cos(base_rad) * fan_radius
		)
		arc_pos -= Vector2(fan_card_width / 2.0, 0).rotated(base_rad)
		var local = (local_pos - arc_pos).rotated(-base_rad)
		if local.x >= 0 and local.x < fan_card_width and local.y >= 0 and local.y < fan_card_height:
			return card
	return null

# =============================================
#  拖拽排序 / Drag Reorder
# =============================================

## 开始拖拽 / Start drag
func _start_drag(card: Control, global_pos: Vector2):
	is_dragging = true
	dragging_card = card
	drag_original_index = cards.find(card)
	drag_insert_index = drag_original_index

	# 计算抓取偏移（牌不跳到指针位置）/ Calculate grab offset (card doesn't jump to pointer)
	drag_offset = card.position - (global_pos - cards_container.global_position)

	# 提升到最高层 / Raise to top layer
	card.z_index = cards.size() + 10

	# 清除悬停 / Clear hover
	if hovered_card == card:
		card.set_hovered(false)
		hovered_card = null

	# 停止该牌的排列动画 / Stop arrange animation for this card
	if card_tweens.has(card) and card_tweens[card] and card_tweens[card].is_valid():
		card_tweens[card].kill()
	card_tweens.erase(card)

	# 其余牌留空位 / Other cards leave a gap
	_arrange_cards_with_gap(drag_original_index, card)
	_log("开始拖拽: " + card.get_card_name() + " 原位置: " + str(drag_original_index))

## 更新拖拽位置 / Update drag position
func _update_drag(global_pos: Vector2):
	if not is_dragging or dragging_card == null:
		return

	# 直接跟随指针（无 tween）/ Follow pointer directly (no tween)
	var local_pos = global_pos - cards_container.global_position
	dragging_card.position = local_pos + drag_offset
	dragging_card.rotation = 0  # 拖拽时保持水平 / Keep horizontal during drag

	# 计算新插入位置 / Calculate new insert position
	var new_index = _calculate_insert_index(global_pos)
	if new_index != drag_insert_index:
		drag_insert_index = new_index
		_arrange_cards_with_gap(drag_insert_index, dragging_card)

## 结束拖拽（放置到新位置）/ End drag (place at new position)
func _end_drag():
	if not is_dragging:
		return

	var card = dragging_card
	var target_index = clamp(drag_insert_index, 0, cards.size() - 1)

	# 在数组中移动卡牌 / Move card in array
	cards.erase(card)
	cards.insert(target_index, card)

	_log("拖拽结束: " + card.get_card_name() + " 新位置: " + str(target_index))

	# 重置拖拽状态 / Reset drag state
	is_dragging = false
	dragging_card = null
	drag_original_index = -1
	drag_insert_index = -1
	drag_offset = Vector2.ZERO

	# 所有牌归位 / All cards return to position
	_arrange_cards()

## 取消拖拽（回到原位）/ Cancel drag (return to original position)
func _cancel_drag():
	if not is_dragging:
		return

	var card = dragging_card
	var original = drag_original_index

	# 重置拖拽状态 / Reset drag state
	is_dragging = false
	dragging_card = null
	drag_original_index = -1
	drag_insert_index = -1
	drag_offset = Vector2.ZERO

	# 确保卡牌在原位 / Ensure card at original position
	cards.erase(card)
	cards.insert(clamp(original, 0, cards.size()), card)

	_arrange_cards()

## 根据指针位置计算插入索引 / Calculate insert index from pointer position
func _calculate_insert_index(global_pos: Vector2) -> int:
	_update_fan_center()
	var local_pos = global_pos - cards_container.global_position

	# 计算指针相对于扇形中心的角度 / Calculate pointer angle relative to fan center
	var dx = local_pos.x - fan_center.x
	var dy = -(local_pos.y - fan_center.y)  # 翻转 Y 轴 / Flip Y axis
	var pointer_angle = rad_to_deg(atan2(dx, dy))

	# 构建非拖拽卡牌的角度列表 / Build angle list of non-dragging cards
	var arranged_cards: Array = []
	for c in cards:
		if c != dragging_card:
			arranged_cards.append(c)

	if arranged_cards.is_empty():
		return 0

	var count = arranged_cards.size()
	var angle_step = _calculate_angle_step_for_count(count + 1)  # +1 包括空位 / +1 includes gap
	var total_fan_angle = angle_step * count  # count 个间隔（含空位）/ count gaps (with gap)
	var start_angle = -total_fan_angle / 2.0

	# 查找插入位置：指针角度落在哪两张牌之间
	# Find insert position: which gap the pointer angle falls in
	for i in range(count):
		var card_angle = start_angle + i * angle_step
		if i == 0 and pointer_angle < card_angle:
			return 0
		if i > 0:
			var prev_angle = start_angle + (i - 1) * angle_step
			var mid = (prev_angle + card_angle) / 2.0
			if pointer_angle < mid:
				return _get_real_index(arranged_cards, i - 1)

	return _get_real_index(arranged_cards, count - 1) + 1

## 辅助：把过滤后列表的索引转为原 cards 数组索引
## Helper: convert filtered list index to original cards array index
func _get_real_index(arranged_cards: Array, filter_index: int) -> int:
	if filter_index < 0 or filter_index >= arranged_cards.size():
		return cards.size() - 1
	var card = arranged_cards[filter_index]
	return cards.find(card)

## 计算指定数量的角度步长 / Calculate angle step for given count
func _calculate_angle_step_for_count(count: int) -> float:
	if count <= 1:
		return 0.0
	var total = fan_max_angle_step * (count - 1)
	if total <= fan_max_angle:
		return fan_max_angle_step
	var step = fan_max_angle / float(count - 1)
	return max(fan_min_angle_step, step)

## 排列牌组并在指定位置留空位（拖拽预览）
## Arrange cards and leave gap at position (drag preview)
func _arrange_cards_with_gap(gap_index: int, skip_card: Control):
	_update_fan_center()

	# 构建要排列的牌列表（排除被拖拽的牌）/ Build arrange list (exclude dragging card)
	var arranged: Array = []
	for c in cards:
		if c != skip_card:
			arranged.append(c)

	if arranged.is_empty():
		return

	# 总槽位 = 排列的牌 + 1 个空位 / Total slots = arranged cards + 1 gap
	var total_slots = arranged.size() + 1
	var angle_step = _calculate_angle_step_for_count(total_slots)
	var total_fan_angle = angle_step * max(0, total_slots - 1)
	var start_angle = -total_fan_angle / 2.0

	var card_idx = 0
	for slot in range(total_slots):
		if slot == gap_index:
			continue  # 空位，跳过 / Gap, skip
		if card_idx >= arranged.size():
			break
		var card = arranged[card_idx]
		card_idx += 1

		# 计算该槽位的角度 / Calculate angle for this slot
		var base_angle = start_angle + slot * angle_step
		card_base_angles[card] = base_angle

		card.z_index = slot

		var target_rad = deg_to_rad(base_angle)
		var arc_point = Vector2(
			fan_center.x + sin(target_rad) * fan_radius,
			fan_center.y - cos(target_rad) * fan_radius
		)
		var target_pos = arc_point - Vector2(fan_card_width / 2.0, 0).rotated(target_rad)

		card.set_original_position(target_pos)
		_tween_card(card, target_pos, target_rad, fan_arrange_duration)

# =============================================
#  卡牌增删（公共 API）/ Card Add/Remove (Public API)
# =============================================

## 添加一张卡牌（从上方飞入牌扇）/ Add a card (flies in from above)
func add_card(suit: String = "spade", rank: int = 1,) -> Control:
	if cards_in_deck.size() >= 52 + joker_int:
		return
	if jokers && suit == "joker":
		rank = randi_range(14,15)
	if cards_in_deck.has(suit + str(rank)):
		_on_add_card()
		return
	
	
	cards_in_deck.append(suit + str(rank))
	
	var card_scene = load(card_scene_path)
	if not card_scene:
		push_error("CardFan: 无法加载卡牌场景 Cannot load card scene at: " + card_scene_path)
		return null
	var card = card_scene.instantiate()
	card.set_card_data(suit, rank)

	# 先设置入场起始位置：屏幕上方中央 / Set enter start position: above screen center
	_update_fan_center()
	var enter_pos = Vector2(fan_center.x, fan_center.y - fan_radius - 300)
	card.position = enter_pos
	card.rotation = 0
	card.modulate.a = 0.0

	cards_container.add_child(card)
	cards.append(card)

	_arrange_cards_with_enter(card)
	_update_card_count()
	return card

## 添加一张带自定义纹理的卡牌 / Add a card with custom texture
func add_card_with_texture(texture: Texture2D, suit: String = "spade", rank: int = 1) -> Control:
	var card = add_card(suit, rank)
	if card and texture:
		card.set_card_texture(texture)
	return card

## 添加已有的卡牌实例 / Add an existing card instance
func add_card_instance(card: Control):
	if not card:
		return

	_update_fan_center()
	var enter_pos = Vector2(fan_center.x, fan_center.y - fan_radius - 300)
	card.position = enter_pos
	card.rotation = 0
	card.modulate.a = 0.0

	cards_container.add_child(card)
	cards.append(card)

	_arrange_cards_with_enter(card)
	_update_card_count()

## 移除最后一张卡牌 / Remove the last card
func remove_card() -> bool:
	if cards.is_empty():
		return false
	var card = cards.pop_back()

	# 安全检查：如果移除的是正在交互的牌 / Safety check for interactive cards
	if hovered_card == card:
		hovered_card = null
	if dragging_card == card:
		_cancel_drag()
	if last_click_card == card:
		last_click_card = null
		click_pending_emit = false
	if press_card == card:
		press_card = null
	if joystick_play_candidate == card:
		joystick_play_candidate = null

	# 停止动画 / Stop animation
	if card_tweens.has(card) and card_tweens[card] and card_tweens[card].is_valid():
		card_tweens[card].kill()
	card_tweens.erase(card)
	card_base_angles.erase(card)
	cards_in_deck.erase(card.card_suit + str(card.card_rank))
	card.queue_free()
	_arrange_cards()
	_update_card_count()
	return true

## 移除指定卡牌 / Remove a specific card
func remove_specific_card(card: Control) -> bool:
	if not cards.has(card):
		return false

	cards.erase(card)

	if hovered_card == card:
		hovered_card = null
	if dragging_card == card:
		_cancel_drag()

	if card_tweens.has(card) and card_tweens[card] and card_tweens[card].is_valid():
		card_tweens[card].kill()
	card_tweens.erase(card)
	card_base_angles.erase(card)
	card.queue_free()
	_arrange_cards()
	_update_card_count()
	return true

# =============================================
#  牌扇排列逻辑 / Fan Arrangement Logic
# =============================================

## 计算角度步长（牌越多角度越小，平滑过渡）
## Calculate angle step (smaller step with more cards, smooth transition)
func _calculate_angle_step() -> float:
	var count = cards.size()
	if count <= 1:
		return 0.0
	var total = fan_max_angle_step * (count - 1)
	if total <= fan_max_angle:
		return fan_max_angle_step
	var step = fan_max_angle / float(count - 1)
	return max(fan_min_angle_step, step)

## 排列所有卡牌（常规，不含入场动画）/ Arrange all cards (normal, no enter animation)
func _arrange_cards():
	if cards.is_empty():
		return
	_update_fan_center()
	_do_arrange(null)

## 排列所有卡牌，新牌使用入场动画 / Arrange all cards, new card uses enter animation
func _arrange_cards_with_enter(entering_card: Control):
	if cards.is_empty():
		return
	_update_fan_center()
	_do_arrange(entering_card)

## 核心排列逻辑 / Core arrange logic
func _do_arrange(entering_card: Control):
	var count = cards.size()
	var angle_step = _calculate_angle_step()
	var total_fan = angle_step * max(0, count - 1)
	var start_angle = -total_fan / 2.0

	var hovered_index = -1
	if hovered_card:
		hovered_index = cards.find(hovered_card)

	for i in range(count):
		var card = cards[i]

		# 拖拽中的牌不参与排列 / Skip dragging card
		if is_dragging and card == dragging_card:
			continue

		var base_angle = start_angle + i * angle_step
		card_base_angles[card] = base_angle

		card.z_index = count if card == hovered_card else i

		var target_angle = base_angle
		# 邻牌避让 / Neighbor avoidance
		if hovered_index >= 0 and card != hovered_card:
			if i < hovered_index:
				target_angle -= hover_avoid_angle
			else:
				target_angle += hover_avoid_angle

		var target_rad = deg_to_rad(target_angle)
		var arc_point = Vector2(
			fan_center.x + sin(target_rad) * fan_radius,
			fan_center.y - cos(target_rad) * fan_radius
		)
		var target_pos = arc_point - Vector2(fan_card_width / 2.0, 0).rotated(target_rad)

		# 悬停上浮 / Hover float
		if card == hovered_card:
			target_pos += Vector2(0, -hover_offset).rotated(target_rad)

		var base_rad = deg_to_rad(base_angle)
		var base_arc = Vector2(
			fan_center.x + sin(base_rad) * fan_radius,
			fan_center.y - cos(base_rad) * fan_radius
		)
		card.set_original_position(base_arc - Vector2(fan_card_width / 2.0, 0).rotated(base_rad))

		if card == entering_card:
			_tween_card_enter(card, target_pos, target_rad)
		else:
			_tween_card(card, target_pos, target_rad, fan_arrange_duration)

## 更新悬停/避让位置（不改变基础角度）/ Update hover/avoidance positions
func _update_hover_positions():
	if cards.is_empty():
		return
	var count = cards.size()
	var hovered_index = -1
	if hovered_card:
		hovered_index = cards.find(hovered_card)

	for i in range(count):
		var card = cards[i]

		if is_dragging and card == dragging_card:
			continue

		var base_angle = card_base_angles.get(card, 0.0)
		card.z_index = count if card == hovered_card else i

		var target_angle = base_angle
		if hovered_index >= 0 and card != hovered_card:
			if i < hovered_index:
				target_angle -= hover_avoid_angle
			else:
				target_angle += hover_avoid_angle

		var target_rad = deg_to_rad(target_angle)
		var arc_point = Vector2(
			fan_center.x + sin(target_rad) * fan_radius,
			fan_center.y - cos(target_rad) * fan_radius
		)
		var target_pos = arc_point - Vector2(fan_card_width / 2.0, 0).rotated(target_rad)

		if card == hovered_card:
			target_pos += Vector2(0, -hover_offset).rotated(target_rad)

		_tween_card(card, target_pos, target_rad, hover_duration)

## 更新扇形中心点（水平居中于屏幕，牌扇弧顶在屏幕中心偏下）
## Update fan center (horizontally centered, arc top at screen center + offset)
func _update_fan_center():
	var viewport_size = get_viewport_rect().size
	var container_gp = cards_container.global_position
	var arc_top_y = viewport_size.y / 2.0 + 50.0
	fan_center = Vector2(
		viewport_size.x / 2.0 - container_gp.x,
		arc_top_y - container_gp.y + fan_radius
	)

# =============================================
#  动画工具 / Animation Utilities
# =============================================

## 常规卡牌动画（位置 + 旋转）/ Normal card animation (position + rotation)
func _tween_card(card: Control, target_pos: Vector2, target_rot: float, duration: float):
	if card_tweens.has(card) and card_tweens[card] and card_tweens[card].is_valid():
		card_tweens[card].kill()
	# 确保透明度恢复（入场动画可能被中断，alpha 卡在半透明）
	# Ensure opacity restored (enter animation may be interrupted, alpha stuck at partial)
	card.modulate.a = 1.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(true)
	tween.tween_property(card, "position", target_pos, duration)
	tween.tween_property(card, "rotation", target_rot, duration)
	card_tweens[card] = tween

## 新牌入场动画（从上方飞入 + 淡入）/ New card enter animation (fly in + fade in)
func _tween_card_enter(card: Control, target_pos: Vector2, target_rot: float):
	if card_tweens.has(card) and card_tweens[card] and card_tweens[card].is_valid():
		card_tweens[card].kill()
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	tween.tween_property(card, "position", target_pos, fan_enter_duration)
	tween.tween_property(card, "rotation", target_rot, fan_enter_duration)
	tween.tween_property(card, "modulate:a", 1.0, fan_enter_duration * 0.5)
	card_tweens[card] = tween

# =============================================
#  调试按钮 / Debug Buttons
# =============================================

func _on_add_card():
	var suits = ["spade", "heart", "club", "diamond"] #NOTE if joker needed put in this arrary
	if jokers:
		suits.append("joker")
	add_card(suits[randi() % suits.size()], (randi() % 13) + 1)

func _on_remove_card():
	remove_card()

func _update_card_count():
	if is_instance_valid(card_count_label):
		card_count_label.text = "count: %d" % cards.size()

# =============================================
#  公共接口 / Public API
# =============================================

## 获取所有卡牌数据 / Get all cards data as Array of Dictionaries
func get_all_cards_data() -> Array:
	var result = []
	for card in cards:
		result.append(card.get_card_data())
	return result

## 获取卡牌数组（高级用法）/ Get cards array (advanced usage)
func get_cards() -> Array:
	return cards.duplicate()

## 获取卡牌数量 / Get card count
func get_card_count() -> int:
	return cards.size()

## 清除所有卡牌 / Clear all cards
func clear_all_cards():
	# 取消拖拽 / Cancel drag
	if is_dragging:
		is_dragging = false
		dragging_card = null
		drag_original_index = -1
		drag_insert_index = -1
		drag_offset = Vector2.ZERO

	for card in cards:
		if card_tweens.has(card) and card_tweens[card] and card_tweens[card].is_valid():
			card_tweens[card].kill()
		card.queue_free()
	cards.clear()
	card_tweens.clear()
	card_base_angles.clear()
	hovered_card = null

	# 重置所有交互状态 / Reset all interaction state
	is_pressing = false
	long_press_triggered = false
	is_playing_card = false
	last_click_card = null
	click_pending_emit = false
	press_card = null
	joystick_play_candidate = null
	joystick_prev_had_card = false
	touch_active = false
	touch_finger_index = -1

	_update_card_count()
