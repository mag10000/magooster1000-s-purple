extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	$MarkdownLabel.text = ""


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$MarkdownLabel.markdown_text = text
	if account.format_mode == "BBcode":
		$MarkdownLabel.hide()
	else:
		$MarkdownLabel.show()
