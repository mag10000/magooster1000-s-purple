extends CheckButton


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if button_pressed:
		text = tr("Dark Mode")
		icon = load("res://Colebemis-Feather-Moon.512.png")
	else:
		text = tr("Light Mode")
		icon = load("res://Colebemis-Feather-Sun.512.png")
