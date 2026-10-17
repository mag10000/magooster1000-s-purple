extends Control
## 选牌光标小点 / Card Selection Cursor Dot
## 由摇杆控制，在牌扇区域内移动，触发卡牌悬停效果
## Controlled by joystick, moves within fan area, triggers hover effects

const DOT_RADIUS: float = 6.0
const DOT_COLOR: Color = Color(1.0, 0.3, 0.3, 0.85)
const OUTLINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.9)
const OUTLINE_WIDTH: float = 1.5

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	visible = false
	custom_minimum_size = Vector2(DOT_RADIUS * 2, DOT_RADIUS * 2)
	size = Vector2(DOT_RADIUS * 2, DOT_RADIUS * 2)

func _draw():
	var center = Vector2(DOT_RADIUS, DOT_RADIUS)
	draw_circle(center, DOT_RADIUS + OUTLINE_WIDTH, OUTLINE_COLOR)
	draw_circle(center, DOT_RADIUS, DOT_COLOR)

func show_dot():
	visible = true

func hide_dot():
	visible = false

## 获取小点中心位置（用于碰撞检测）/ Get center position (for hit detection)
func get_center_position() -> Vector2:
	return position + Vector2(DOT_RADIUS, DOT_RADIUS)
