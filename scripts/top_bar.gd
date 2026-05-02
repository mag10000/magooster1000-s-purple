extends PanelContainer

# ttps://www.youtube.com/watch?v=IbMeHU7um_o

var moving := false
var mouse_start: Vector2i

func _ready():
	if get_window().mode == Window.MODE_FULLSCREEN:
		$"../../Handles".can_resize = false

func _on_minimize_button_pressed():
	get_window().set_mode(Window.MODE_MINIMIZED)
	$"../../Handles".can_resize = true


func _on_maxmize_button_pressed():
	match get_window().mode:
		Window.MODE_WINDOWED:
			get_window().set_mode(Window.MODE_FULLSCREEN)
			$"../../Handles".can_resize = false
		Window.MODE_FULLSCREEN:
			get_window().set_mode(Window.MODE_WINDOWED)
			$"../../Handles".can_resize = true


func _on_close_button_pressed():
	get_tree().quit()


func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if !moving:
			mouse_start = get_viewport().get_mouse_position()
		moving = event.is_pressed()

func _process(delta):
	if moving:
		var mouse_now := Vector2i(get_viewport().get_mouse_position())
		get_window().position += mouse_now - mouse_start
