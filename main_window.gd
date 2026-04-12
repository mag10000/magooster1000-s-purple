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
