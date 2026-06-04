extends Node

var channel_id
var usrn = ""
var logged_in = false
var purple_version = "1.1.0"
var version_label = "dev"
var theme = "base theme"
var settings_loaded = false
var settings = {}
var theme_data = {"name" : "base theme","base" : true}
var format_mode = "markdown"
var use_formatting = false
var dark_or_light = "dark"
var light_bg = "4b4062"
var dark_bg = "1a1525"
var local_settings_loaded = false
var fav_emojis = []

func _ready():
	get_window().title = "MP - magooster1000's purple"
	load_local_saves()
	Console._toogle_key = KEY_BACKSLASH
	Console.enable_console = true
	Console.print("Welcome to the console.")
	Console.print("type \"/help\" to get a list of commands.")
	add_command("help",list_commands,"List all the commands.")
	add_command("generate_emoji_list",Emoji.parser,"Create a file with all emoji categories and emojis.",)

func list_commands(args):
	Console.print("Commands:")
	for command in Console._commands_list:
		Console.print("    /" + str(command._name) + ": " + command._description)

func add_command(_name:String,_callback:Callable,_description:String = "",_usage_example:String = "",_is_cheat:bool = false):
	var command = ConsoleCommand.new(_name)
	command.set_name(_name)
	command.set_callback(_callback)
	command.set_description(_description)
	command.set_usage_example(_usage_example)
	command.set_cheat(_is_cheat)
	Console.add_command(command)

func talo_save(password : String,username : String):
	var file = FileAccess.open("user://user_talo_email.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify({"usrn" : username,"pass" : password}))
	file.close()
	file = null

func talo_load():
	if FileAccess.file_exists("user://user_talo_email.dat"):
		var file = FileAccess.open("user://user_talo_email.dat", FileAccess.READ)
		var new_json = JSON.new()
		var content = new_json.parse(file.get_as_text())
		return new_json.get_data()
	else:
		print("could not find user_talo_email.dat")

func local_save_settings(data : Dictionary):
	var file = FileAccess.open("user://settings.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_local_saves():
	if FileAccess.file_exists("user://settings.dat"):
		var text_data = FileAccess.get_file_as_string("user://settings.dat")
		var json_data = JSON.parse_string(text_data)
		settings = json_data
		local_settings_loaded = true
