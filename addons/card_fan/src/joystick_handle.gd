extends Control
## 摇杆手柄绘制 / Joystick Handle Drawing
## 根据激活状态改变颜色 / Changes color based on active state

func _draw():
	var center = Vector2(size.x / 2, size.y / 2)
	var radius = min(size.x, size.y) / 2
	var parent = get_parent()
	var color = Color(1.0, 1.0, 1.0, 0.8) if parent and parent.has_method("is_active") and parent.is_active() else Color(0.8, 0.8, 0.8, 0.6)
	draw_circle(center, radius, color)
