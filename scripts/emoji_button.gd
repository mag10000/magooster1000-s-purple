extends Button

var dir_special = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if dir_special:
		$MenuBar.position = Vector2(182,0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	$"../../../..".emoji_pressed(icon.resource_path.get_file().replace(".png",""))


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed:
			$MenuBar.show()

func _input(event):
	await get_tree().create_timer(0.1).timeout
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed:
			$MenuBar.hide()


func _on_add_to_favorites_pressed():
	$"../../../..".add_to_favorites(icon.resource_path.get_file().replace(".png",""))
