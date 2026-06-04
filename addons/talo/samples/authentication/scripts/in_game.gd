extends Node2D

signal go_to_change_password
signal go_to_change_email
signal go_to_change_identifier
signal go_to_delete
signal logout_success

@onready var username: Label = %Username

func _ready() -> void:
	Talo.players.identified.connect(_on_player_identified)

	# identified signal emitted before the connection were made
	if Talo.current_player:
		_on_player_identified(Talo.current_player)

	# listen for the player changing their identifier
	%ChangeIdentifier.identifier_change_success.connect(
		func (): _on_player_identified(Talo.current_player)
	)

func _on_player_identified(player: TaloPlayer) -> void:
	%Usernameacutual.text = "[b]" + Talo.current_alias.identifier + "?"
	account.usrn = Talo.current_alias.identifier
	account.logged_in = true
	
	var options := Talo.channels.GetChannelsOptions.new()
	options.page = 0
	var res := await Talo.channels.get_channels(options)
	var channels: = res.channels
	var has_personal_channel = false
	for channel in channels:
		if channel.name == Talo.current_alias.identifier + Talo.current_player.id:
			has_personal_channel = true
			account.channel_id = channel.id
	
	if not has_personal_channel:
		create_channel(Talo.current_alias.identifier + Talo.current_player.id)
	
	var saves = await Talo.saves.get_saves()
	for save in saves:
		if save.name == "settings":
			account.settings = save.content
			account.settings_loaded = true
		if save.name == "fav_emojis":
			account.fav_emojis = save.content["emojis"]
	$UI/MarginContainer/VBoxContainer/Home.disabled = false
	$UI/MarginContainer/VBoxContainer/ChangePassword.disabled = false
	$UI/MarginContainer/VBoxContainer/ChangeEmail.disabled = false
	$UI/MarginContainer/VBoxContainer/ChangeIdentifier.disabled = false
	$UI/MarginContainer/VBoxContainer/Logout.disabled = false
	$UI/MarginContainer/VBoxContainer/Delete.disabled = false
	await get_tree().create_timer(3).timeout



func create_channel(_name):
	var options := Talo.channels.CreateChannelOptions.new()
	options.name = _name
	options.auto_cleanup = false
	options.props = {
		prop_key = "prop_value"
	}
	var channel := await Talo.channels.create(options)
	account.channel_id = channel.id


func _on_change_password_pressed() -> void:
	go_to_change_password.emit()

func _on_change_email_pressed() -> void:
	go_to_change_email.emit()

func _on_change_identifier_pressed() -> void:
	go_to_change_identifier.emit()

func _on_logout_pressed() -> void:
	await Talo.player_auth.logout()
	logout_success.emit()

func _on_delete_pressed() -> void:
	go_to_delete.emit()

func _on_home_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _process(delta):
	if account.dark_or_light == "dark":
		$UI/Background.color = account.dark_bg
		$UI/MarginContainer.theme = load("res://main theme.tres")
	else:
		$UI/Background.color = account.light_bg
		$UI/MarginContainer.theme = load("res://main theme light.tres")
