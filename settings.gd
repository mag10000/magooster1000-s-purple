extends Control

var freeze_loading = false

func _on_button_pressed():
	Talo.saves.create_save("settings",{"show_status_bar" : $Panel/VBoxContainer/CheckButtonStatusBar.button_pressed,"theme" : account.theme_data,"language" : $Panel/VBoxContainer/laungage/LanguageOptionButton.selected})
	if not $Panel/VBoxContainer/CheckButtonStatusBar.button_pressed:
		$"../../StatusBar".hide()
	else:
		$"../../StatusBar".show()
	account.settings = {"show_status_bar" : $Panel/VBoxContainer/CheckButtonStatusBar.button_pressed,"theme" : account.theme_data,"laungage" : $Panel/VBoxContainer/laungage/LanguageOptionButton.selected}
	freeze_loading = false
	hide()

func _process(_delta):
	if account.settings_loaded && not freeze_loading:
		var settings = account.settings
		if settings.has("show_status_bar"):
			if settings.show_status_bar == true:
				$Panel/VBoxContainer/CheckButtonStatusBar.button_pressed = true
				$"../../StatusBar".show()
			else:
				$Panel/VBoxContainer/CheckButtonStatusBar.button_pressed = false
				$"../../StatusBar".hide()
		if settings.has("theme"):
			account.theme = settings.theme.name
			account.theme_data = settings.theme
			$Panel/VBoxContainer/theme/TextEditTheme.text = tr("Theme: ") + settings.theme.name
		if settings.has("language"):
			$Panel/VBoxContainer/laungage/LanguageOptionButton.selected = settings.language
			$Panel/VBoxContainer/laungage/LanguageOptionButton._on_language_selected(settings.language)
