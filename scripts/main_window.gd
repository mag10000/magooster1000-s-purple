extends Control


func _ready():
	show()
	get_window().min_size = Vector2i(600,400)
	get_window().max_size = Vector2i(1552,848)


func _on_account_button_pressed():
	get_tree().change_scene_to_file("res://godot google auth/main.tscn")


func _on_settings_button_pressed():
	if account.logged_in:
		$Layout/Contents/settings.visible = !$Layout/Contents/settings.visible
		$Layout/Contents/settings.freeze_loading = !$Layout/Contents/settings.freeze_loading


func _on_button_pressed():
	OS.shell_open("https://github.com/mag10000/magooster1000-s-purple/issues/new")


func _on_close_button_pressed():
	$Layout/Contents/settings.visible = false
	$Layout/Contents/settings.freeze_loading = false

func _process(delta):
	if account.dark_or_light == "dark":
		$Layout/Contents/settings/Panel.theme = load("res://main theme.tres")
	else:
		$Layout/Contents/settings/Panel.theme = load("res://main theme light.tres")
