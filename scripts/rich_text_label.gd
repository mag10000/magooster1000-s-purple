extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	$MarkdownLabel.text = ""


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	for e in Emoji.emojis:
		var data = Emoji.emojis[e]
		var emoji_name = e
		text = text.replace(":" + emoji_name + ":","[img=26x26]" + data.path + "[/img]")
	$MarkdownLabel.markdown_text = text
	if account.format_mode == "BBcode":
		$MarkdownLabel.hide()
	else:
		$MarkdownLabel.show()
