extends Control

var token = Token.token

func _ready():
	var discord_bot = $DiscordBot
	
	discord_bot.TOKEN = token
	discord_bot.login()
	
	discord_bot.connect("bot_ready",_on_bot_ready)
	discord_bot.connect("message_create",_on_message_create)

func _on_bot_ready(bot : DiscordBot):
	print("bot: ",str(bot)," is ready!")
	
	var dm_channel = await bot.create_dm_channel("1373770973475635441")
	bot.send(dm_channel.id, "Purple Bot Went Online by user: " + account.usrn + "
To send messages to purple user's join the purple discord server at: https://discord.gg/KfNE4bzdxh")
	print("----------------------------")
	print(await bot.get_channel(dm_channel.id))
	print("----------------------------")

func _on_message_create(bot : DiscordBot,message : Message,channel : Dictionary):
	print(channel)
	#if message.content:
	print("message recived: ", message.content)
	print("___________________________________________________________")
	if message.author.username != "Purple Chat" && channel.id == "1500134572913066165":
		bot.reply(message,"hello this is a test of the purple bot <:purplelogo:1500135069077999626>,
you said \"" + message.content + "\"")
	var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
