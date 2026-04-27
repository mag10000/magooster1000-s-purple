extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $OptionButton.selected == 0:
		$TextureRect.texture = load("res://Pictogrammers-Material-Code-brackets.512.png")
	else:
		$TextureRect.texture = load("res://Github-Octicons-Markdown-16.512.png")
