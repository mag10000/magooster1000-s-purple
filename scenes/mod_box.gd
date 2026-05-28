extends Panel

var title = "TEST MOD"
var author = "Magooster1000 tech"
var discription = "This is a discription"
var page_url = ""
var download_url = ""
var file_name = ""
@onready var title_node = $title
@onready var author_node = $author
@onready var discription_node = $discription


# Called when the node enters the scene tree for the first time.
func _ready():
	discription_node.text = discription
	author_node.text = "Author: " + author
	title_node.text = "[b]Mod Name: " + title


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_view_online_pressed():
	OS.shell_open(page_url)


func _on_download_pressed():
	$"../../../../..".download_mod(download_url,self)
