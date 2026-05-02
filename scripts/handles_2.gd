extends Control

var resizing := false
var resize_node: Control

func _on_right_gui_input(event):
	if event is InputEventMouseButton:
		_gui_input_handling(event,$Left)


func _on_bottom_gui_input(event):
	if event is InputEventMouseButton:
		_gui_input_handling(event,$Top)


func _on_corner_gui_input(event):
	if event is InputEventMouseButton:
		_gui_input_handling(event,$Corner)


func _gui_input_handling(event: InputEventMouse, node: Control) -> void:
	if event.button_index == 1:
		if !resizing:
			resize_node = node
		resizing = event.is_pressed()


func _process(delta):
	if resizing:
		var scene = get_tree().current_scene
		if resize_node in [$Top,$Corner]:
			get_window().size.y = int(scene.get_global_mouse_position().y)
		if resize_node in [$Left,$Corner]:
			get_window().size.x = int(scene.get_global_mouse_position().x)
