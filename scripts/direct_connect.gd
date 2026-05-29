extends Control

var _active_channel_id = account.channel_id

func _ready():
	$RichTextLabel.text = ""
	
	var entries = await Talo.leaderboards.get_entries("message_storage")
	for entrie in entries.entries:
		if entrie.props[1].value == str(_active_channel_id):
			print(entrie.props[0].value)
			$RichTextLabel.text += "
" + entrie.props[0].value
	
	Talo.channels.message_received.connect(_on_message_received)

func _on_message_received(channel: TaloChannel, player_alias: TaloPlayerAlias, message: String) -> void:
	print(message)
	if channel.id == _active_channel_id:
		_add_chat_message("[b]%s:[/b] %s" % [player_alias.identifier, message])

func _add_chat_message(message):
	Console.print("message recived on direct connect:" + message)
	$RichTextLabel.text += "
" + message


func _on_button_pressed():
	var id
	print("----------")
	print($LineEdit/LineEdit.text)
	print("----------")
	if $LineEdit/LineEdit.text == "self":
		print("Helloooo>>>>")
		$RichTextLabel.text += "
[b]%s:[/b] %s" % [account.usrn, $LineEdit.text]
		return

	var search_page := await Talo.players.search($LineEdit/LineEdit.text)
	if not search_page:
		return
	if search_page.count == 0:
		print("No players found")
		return

	var identifiers = []
	var ids = []
	var players = []
	for player in search_page.players:
		identifiers.append(player.get_alias().identifier)
		ids.append(player.id)
		players.append(player)
	
	var channel_name = identifiers[0] + ids[0]
	
	var options := Talo.channels.GetChannelsOptions.new()
	options.page = 0
	var res := await Talo.channels.get_channels(options)

	var channels: Array[TaloChannel] = res.channels
	
	for channel in channels:
		if channel.name == channel_name:
			id = channel.id

	Talo.channels.join(id)

	Talo.channels.send_message(id,$LineEdit.text)
	Talo.leaderboards.add_entry("message_storage",int(Time.get_datetime_string_from_system()),{"message": "[b]%s:[/b] %s" % [Talo.current_alias.identifier, $LineEdit.text],"channel" : id})
	if players[0].aliases[0].identifier == account.usrn:
		$RichTextLabel.text += "[b]%s:[/b] %s" % [account.usrn, $LineEdit.text]
	$LineEdit.text = ""

func _on_line_edit_text_submitted(new_text):
	var id
	print("----------")
	print($LineEdit/LineEdit.text)
	print("----------")
	if $LineEdit/LineEdit.text == "self":
		print("Helloooo>>>>")
		$RichTextLabel.text += "
[b]%s:[/b] %s" % [account.usrn, $LineEdit.text]
		return

	var search_page := await Talo.players.search($LineEdit/LineEdit.text)
	if not search_page:
		return
	if search_page.count == 0:
		print("No players found")
		return

	var identifiers = []
	var ids = []
	var players = []
	for player in search_page.players:
		identifiers.append(player.get_alias().identifier)
		ids.append(player.id)
		players.append(player)
	
	var channel_name = identifiers[0] + ids[0]
	
	var options := Talo.channels.GetChannelsOptions.new()
	options.page = 0
	var res := await Talo.channels.get_channels(options)

	var channels: Array[TaloChannel] = res.channels
	
	for channel in channels:
		if channel.name == channel_name:
			id = channel.id

	Talo.channels.join(id)

	Talo.channels.send_message(id,$LineEdit.text)
	Talo.leaderboards.add_entry("message_storage",int(Time.get_datetime_string_from_system()),{"message": "[b]%s:[/b] %s" % [Talo.current_alias.identifier, $LineEdit.text],"channel" : id})
	if players[0].aliases[0].identifier == account.usrn:
		$RichTextLabel.text += "[b]%s:[/b] %s" % [account.usrn, $LineEdit.text]
	$LineEdit.text = ""

func _process(delta):
	if account.dark_or_light == "dark":
		$ColorRect.color = account.dark_bg
		$LineEdit.theme = load("res://main theme.tres")
		$RichTextLabel.theme = load("res://main theme.tres")
	else:
		$ColorRect.color = account.light_bg
		$LineEdit.theme = load("res://main theme light.tres")
		$RichTextLabel.theme = load("res://main theme light.tres")
