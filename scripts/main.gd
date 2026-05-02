extends Control

var cached_messages = []
var steve_spam = "https://cdn.discordapp.com/emojis/1485771810376257596.webp?size=96&animated=true"
var token = Token.token

func _ready(): 
	if not account.logged_in:
		get_tree().change_scene_to_file("res://godot google auth/main.tscn")
	
	get_scores()

func get_scores():
	cached_messages = []

func _on_bot_ready(bot : DiscordBot):
	print("bot: ",str(bot)," is ready!")

func _on_message_create(bot : DiscordBot,message : Message,channel : Dictionary):
	#if message.content:
	print("message recived: ", message.content)
	print("___________________________________________________________")
	if message.author.username != "Purple Chat" && channel.id == "1485781238403960953":
		bot.reply(message,"hello this is a test of the purple bot <:servericon:1483617328166998136>,
you said \"" + message.content + "\"")



@onready var code = $LineEdit
func _on_line_edit_text_changed(new_text):
	print("hi")
	var res := await Talo.player_auth.verify(code.text)
	if res != OK:
		match Talo.player_auth.last_error.get_code():
			TaloAuthError.ErrorCode.INVALID_CREDENTIALS:
				print("Verification code is incorrect")
			_:
				print(Talo.player_auth.last_error.get_string())
	else:
		print("verified")


func auto_login():
	print("hi!")

func fail_auto_login():
	print("fail")


func _on_rich_text_label_meta_clicked(meta):
	OS.shell_open(str(meta))


func _on_direct_pressed():
	$"Direct Connect".show()
	$Friends.hide()


func _on_friends_pressed():
	$"Direct Connect".hide()
	$Friends.show()

func _process(delta):
	if account.dark_or_light == "dark":
		$Panel.theme = load("res://main theme.tres")
	else:
		$Panel.theme = load("res://main theme light.tres")
