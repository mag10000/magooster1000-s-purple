extends Button

var global_browser = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	if global_browser != null:
		global_browser.queue_free()
	var browser = preload("res://scenes/emoji_browser.tscn").instantiate()
	global_browser = browser
	browser.target = $".."
	$"../..".add_child(browser)
