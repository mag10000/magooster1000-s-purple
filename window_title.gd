extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	text = tr(get_window().title)
	$"../../StatusBar/HBoxContainer/Label".text = "Magooster1000's purple v " + account.purple_version + " - " + account.version_label + " - " + account.theme
	$"../../StatusBar/HBoxContainer/account".text = account.usrn
# + account.usrn
