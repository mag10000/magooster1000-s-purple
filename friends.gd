extends Control

func _process(delta):
	if account.dark_or_light == "dark":
		$ColorRect.color = account.dark_bg
		$LineEdit.theme = load("res://main theme.tres")
		$RichTextLabel.theme = load("res://main theme.tres")
	else:
		$ColorRect.color = account.light_bg
		$LineEdit.theme = load("res://main theme light.tres")
		$RichTextLabel.theme = load("res://main theme light.tres")
