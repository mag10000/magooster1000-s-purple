extends Panel

var target = Node

func _on_atribution_meta_clicked(meta):
	OS.shell_open(meta)

func _ready():
	for i in Emoji.emoji_categories:
		var label = RichTextLabel.new()
		label.fit_content = true
		label.bbcode_enabled = true
		label.text = "[img=35x35]res://art/icons8 emoji icons/" + i + "/main_icon.png[/img] " + i
		label.name = i + "label"
		$ScrollContainer/VBoxContainer.add_child(label)
		var grid = preload("res://scenes/emojigrid.tscn").instantiate()
		grid.name = i
		$ScrollContainer/VBoxContainer.add_child(grid)
	for r in Emoji.emojis:
		var button = preload("res://scenes/emoji_button.tscn").instantiate()
		button.icon = load(Emoji.emojis[r]["path"])
		button.tooltip_text = r.replace("_multia","")
		get_node("ScrollContainer/VBoxContainer/" + Emoji.emojis[r]["category"]).add_child(button)

func emoji_pressed(emoji_name):
	print(emoji_name)
	target.text += " :" + emoji_name.replace("_multia","") + ":"


func _on_button_pressed():
	self.queue_free()


func _on_search_pressed():
	for child in $ScrollContainer/VBoxContainer.get_children():
		if not child.name.contains("label"):
			for emoji_child in child.get_children():
				emoji_child.show()
	if $LineEdit.text == "":
		return
	for child in $ScrollContainer/VBoxContainer.get_children():
		if not child.name.contains("label"):
			for emoji_child in child.get_children():
				if emoji_child.icon.resource_path.get_file().replace(".png","").contains($LineEdit.text):
					pass
				else:
					emoji_child.hide()
