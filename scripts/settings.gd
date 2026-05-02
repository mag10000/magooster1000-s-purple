extends Control

var freeze_loading = false

func _on_button_pressed():
	Talo.saves.create_save("settings",{"show_status_bar" : $Panel/VBoxContainer/CheckButtonStatusBar.button_pressed,"theme" : account.theme_data,"language" : $Panel/VBoxContainer/laungage/LanguageOptionButton.selected,"format_mode" : $"Panel/VBoxContainer/format mode/OptionButton".selected ,"dark_or_light" : $Panel/VBoxContainer/CheckButtonMode.button_pressed,"use_formatting" : $Panel/VBoxContainer/FormatCheckButton.button_pressed})
	if not $Panel/VBoxContainer/CheckButtonStatusBar.button_pressed:
		$"../../StatusBar".hide()
	else:
		$"../../StatusBar".show()
	account.settings = {"show_status_bar" : $Panel/VBoxContainer/CheckButtonStatusBar.button_pressed,"theme" : account.theme_data,"laungage" : $Panel/VBoxContainer/laungage/LanguageOptionButton.selected,"format_mode" : $"Panel/VBoxContainer/format mode/OptionButton".selected,"dark_or_light" : $Panel/VBoxContainer/CheckButtonMode.button_pressed,"use_formatting" : $Panel/VBoxContainer/FormatCheckButton.button_pressed}
	freeze_loading = false
	account.local_save_settings(account.settings)
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
		if settings.has("format_mode"):
			$"Panel/VBoxContainer/format mode/OptionButton".selected = settings.format_mode
			account.format_mode = $"Panel/VBoxContainer/format mode/OptionButton".get_item_text(settings.format_mode)
		if settings.has("dark_or_light"):
			$Panel/VBoxContainer/CheckButtonMode.button_pressed = settings.dark_or_light
			if settings.dark_or_light == true:
				account.dark_or_light = "dark"
			else:
				account.dark_or_light = "light"
		if settings.has("use_formatting"):
			$Panel/VBoxContainer/FormatCheckButton.button_pressed = settings.use_formatting
			account.use_formatting = settings.use_formatting
	
	
	
	# Local Load
	if account.local_settings_loaded && not freeze_loading:
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
		if settings.has("format_mode"):
			$"Panel/VBoxContainer/format mode/OptionButton".selected = settings.format_mode
			account.format_mode = $"Panel/VBoxContainer/format mode/OptionButton".get_item_text(settings.format_mode)
		if settings.has("dark_or_light"):
			$Panel/VBoxContainer/CheckButtonMode.button_pressed = settings.dark_or_light
			if settings.dark_or_light == true:
				account.dark_or_light = "dark"
			else:
				account.dark_or_light = "light"
		if settings.has("use_formatting"):
			$Panel/VBoxContainer/FormatCheckButton.button_pressed = settings.use_formatting
			account.use_formatting = settings.use_formatting
