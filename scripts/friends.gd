extends Control

var friends = []
var outgoing_friends = []
var requests = []
var _friends: Array[TaloPlayerAlias] = []
var _pending_requests: Array[TaloPlayerAlias] = []
var _outgoing_requests: Array[TaloPlayerAlias] = []
var current_friend = null
var msgs = {}

#var presence := await Talo.player_presence.get_presence(player_id)
func _ready():
	setup()

func setup():
	if account.logged_in:
		var res := await Talo.player_presence.update_presence(true)
	else:
		return
	$RichTextLabel.text = ""
	Talo.player_presence.presence_changed.connect(_on_presence_changed)
	update_friends()
	
	var entries = await Talo.leaderboards.get_entries("friends_message_storage")
	if entries:
		var new_dict = {}
		for entrie in entries.entries:
			print("Entry found: " + entrie.props[2].value + ":" + entrie.props[0].value)
			if entrie.props[2].value.to_lower() == account.usrn.to_lower():
				print(entrie.props[1].value + ":" + entrie.props[0].value)
				print("recivied!")
				new_dict[entrie.props[1].value + "|||" + str(entrie.score)] = "[b]" + entrie.props[1].value + "[/b]: " + entrie.props[0].value
			elif entrie.props[1].value.to_lower() == account.usrn.to_lower():
				print("_____________________________________________________________________________________________________")
				print(entrie.props[1].value + ":" + entrie.props[0].value)
				print("from self!")
				new_dict[entrie.props[2].value + "|||" + str(entrie.score)] = "[b]You[/b]: " + entrie.props[0].value
			print(entrie.props[1].value == account.usrn)
			print(entrie.props[1].value)
		msgs = new_dict
		print("_______________")
		print(entries.entries)
		print(new_dict)
		print("---------------")
			#entrie.props[0].value

func _on_message_received(player_alias: TaloPlayerAlias, message: String):
	Console.print("%s sent: %s" % [player_alias.identifier, message])
	var person = message.split("[//*&MPersom:")[1].replace(":M&*//]","")
	if account.usrn != person:
		return
	#msgs.append(player_alias.identifier + ":" + message.split("[//*&MPersom:")[1].replace(":M&*//]",""))

func _process(delta):
	if current_friend:
		$FriendTitle.text = "[b]" + current_friend.identifier + "[/b]"
	else:
		$RichTextLabel.text = ""
		$FriendTitle.text = ""
	if account.dark_or_light == "dark":
		$ColorRect.color = account.dark_bg
		$LineEdit.theme = load("res://main theme.tres")
		$RichTextLabel.theme = load("res://main theme.tres")
		$FriendsPanel.theme = load("res://main theme.tres")
		$PopupGray/Panel.theme = load("res://main theme.tres")
	else:
		$ColorRect.color = account.light_bg
		$LineEdit.theme = load("res://main theme light.tres")
		$RichTextLabel.theme = load("res://main theme light.tres")
		$FriendsPanel.theme = load("res://main theme light.tres")
		$PopupGray/Panel.theme = load("res://main theme light.tres")
	$RichTextLabel.text = ""
	for msg in msgs:
		if current_friend:
			if msg.split("|||")[0].to_lower() == current_friend.identifier.to_lower():
				if $RichTextLabel.text != "":
					$RichTextLabel.text += "\n" + msgs[msg]
				else:
					$RichTextLabel.text += msgs[msg]

func update_friends():
	await get_tree().create_timer(2).timeout
	refresh_all_data()
	friends = get_friends()
	outgoing_friends = get_outgoing_requests() 
	requests = get_pending_requests() 
	if friends.size() < 1:
		$FriendsPanel/VBoxContainer/FriendsLabel.hide()
		$FriendsPanel/VBoxContainer/friends.hide()
	else:
		$FriendsPanel/VBoxContainer/FriendsLabel.show()
		$FriendsPanel/VBoxContainer/friends.show()
	if outgoing_friends.size() < 1:
		$FriendsPanel/VBoxContainer/PendingLabel.hide()
		$FriendsPanel/VBoxContainer/pending.hide()
	else:
		$FriendsPanel/VBoxContainer/PendingLabel.show()
		$FriendsPanel/VBoxContainer/pending.show()
	if requests.size() < 1:
		$FriendsPanel/VBoxContainer/RequestsLabel.hide()
		$FriendsPanel/VBoxContainer/requests.hide()
	else:
		$FriendsPanel/VBoxContainer/RequestsLabel.show()
		$FriendsPanel/VBoxContainer/requests.show()
	for child in $FriendsPanel/VBoxContainer/friends/VBoxContainer.get_children(): if child: child.queue_free()
	for child in $FriendsPanel/VBoxContainer/pending/VBoxContainer.get_children(): if child: child.queue_free()
	for child in $FriendsPanel/VBoxContainer/requests/VBoxContainer.get_children(): if child: child.queue_free()
	for f in friends:
		var button = preload("res://scenes/friendsbutton.tscn").instantiate()
		button.talo_alias = f
		button.type = "friend"
		$FriendsPanel/VBoxContainer/friends/VBoxContainer.add_child(button)
	for p in outgoing_friends:
		var button = preload("res://scenes/friendsbutton.tscn").instantiate()
		button.talo_alias = p
		button.type = "pending"
		$FriendsPanel/VBoxContainer/pending/VBoxContainer.add_child(button)
	for r in requests:
		var button = preload("res://scenes/friendsbutton.tscn").instantiate()
		button.talo_alias = r
		button.type = "request"
		$FriendsPanel/VBoxContainer/requests/VBoxContainer.add_child(button)
	var entries = await Talo.leaderboards.get_entries("friends_message_storage")
	print("------------")
	print(entries)
	print("------------")
	if entries:
		var new_dict = {}
		for entrie in entries.entries:
			print("Entry found: " + entrie.props[2].value + ":" + entrie.props[0].value)
			if entrie.props[2].value.to_lower() == account.usrn.to_lower():
				if not msgs.has(entrie.props[1].value + "|||" + str(entrie.score)):
					account.play_sound("random_blip")
				print(entrie.props[1].value + ":" + entrie.props[0].value)
				print("recivied!")
				new_dict[entrie.props[1].value + "|||" + str(entrie.score)] = "[b]" + entrie.props[1].value + "[/b]: " + entrie.props[0].value
			elif entrie.props[1].value.to_lower() == account.usrn.to_lower():
				print("_____________________________________________________________________________________________________")
				print(entrie.props[1].value + ":" + entrie.props[0].value)
				print("from self!")
				new_dict[entrie.props[2].value + "|||" + str(entrie.score)] = "[b]You[/b]: " + entrie.props[0].value
			print(entrie.props[1].value == account.usrn)
			print(entrie.props[1].value)
		msgs = new_dict
		print("_______________")
		print(entries.entries)
		print(new_dict)
		print("---------------")
	await get_tree().create_timer(2).timeout
	update_friends()

func _on_attribution_meta_clicked(meta):
	OS.shell_open(meta)

func _on_presence_changed(presence: TaloPlayerPresence, online_changed: bool, custom_status_changed: bool) -> void:
	# check if this player is in our friends list
	if friends.has(presence.player_alias.id) or outgoing_friends.has(presence.player_alias.id) or requests.has(presence.player_alias.id):
		if online_changed:
			if presence.online:
				Console.print("%s is now online" % presence.player_alias.identifier)
				for button in $FriendsPanel/VBoxContainer/friends/VBoxContainer.get_children():
					if button: if button.talo_alias.identifier == presence.player_alias.identifier:
							button.icon = load("res://art/icons8 emoji icons/internet/good wifi.png")
				for button in $FriendsPanel/VBoxContainer/pending/VBoxContainer.get_children():
					if button: if button.talo_alias.identifier == presence.player_alias.identifier:
							button.icon = load("res://art/icons8 emoji icons/internet/good wifi.png")
				for button in $FriendsPanel/VBoxContainer/requests/VBoxContainer.get_children():
					if button: if button.talo_alias.identifier == presence.player_alias.identifier:
							button.icon = load("res://art/icons8 emoji icons/internet/good wifi.png")
			else:
				Console.print("%s is now offline" % presence.player_alias.identifier)
				for button in $FriendsPanel/VBoxContainer/friends/VBoxContainer.get_children():
					if button: if button.talo_alias.identifier == presence.player_alias.identifier:
							button.icon = load("res://art/icons8 emoji icons/internet/no wifi.png")
				for button in $FriendsPanel/VBoxContainer/pending/VBoxContainer.get_children():
					if button: if button.talo_alias.identifier == presence.player_alias.identifier:
							button.icon = load("res://art/icons8 emoji icons/internet/no wifi.png")
				for button in $FriendsPanel/VBoxContainer/requests/VBoxContainer.get_children():
					if button: if button.talo_alias.identifier == presence.player_alias.identifier:
							button.icon = load("res://art/icons8 emoji icons/internet/no wifi.png")
		if custom_status_changed:
			Console.print("They are currently: %s" % presence.custom_status)


func send_friend_request(alias: TaloPlayerAlias) -> bool:
	var subscription := await Talo.player_relationships.subscribe_to(alias.id, TaloPlayerAliasSubscription.RelationshipType.BIDIRECTIONAL)
	return subscription != null

func _on_sendrequest_pressed():
	var players = await Talo.players.search($"PopupGray/Panel/add friend/friend_usrnm".text)
	var alias = null
	if players.players:
		alias = (players.players[0].aliases[0])
	else:
		var text = $"PopupGray/Panel/add friend/friend_usrnm".text
		Console.printerr("Player doesn't exist!")
		$"PopupGray/Panel/add friend/friend_usrnm".add_theme_color_override("font_color",Color.RED)
		$"PopupGray/Panel/add friend/friend_usrnm".text = "Player doesn't exist!"
		await get_tree().create_timer(2).timeout
		$"PopupGray/Panel/add friend/friend_usrnm".add_theme_color_override("font_color",Color.WHITE)
		$"PopupGray/Panel/add friend/friend_usrnm".text = text
		return
	Console.print("Sending friend request to %s..." % alias.identifier,)
	var success := await send_friend_request(alias)

	if success:
		Console.print("Friend request sent to %s" % alias.identifier,)
		$"PopupGray/Panel/add friend".hide()
		$PopupGray.hide()
		update_friends()
	else:
		var text = $"PopupGray/Panel/add friend/friend_usrnm".text
		Console.printerr("Failed to send request to %s" % alias.identifier,)
		Console.printerr(success)
		$"PopupGray/Panel/add friend/friend_usrnm".add_theme_color_override("font_color",Color.RED)
		$"PopupGray/Panel/add friend/friend_usrnm".text = "ERROR"
		await get_tree().create_timer(2).timeout
		$"PopupGray/Panel/add friend/friend_usrnm".add_theme_color_override("font_color",Color.WHITE)
		$"PopupGray/Panel/add friend/friend_usrnm".text = text


func _on_close_pressed():
	$PopupGray.hide()
	$"PopupGray/Panel/add friend".hide()

var show_accept_friend_request_popup_alias = null
func show_accept_friend_request_popup(friend_alias):
	show_accept_friend_request_popup_alias = friend_alias
	$PopupGray.show()
	$"PopupGray/Panel/accept friend".show()


func switch_to_friend(friend_alias):
	current_friend = friend_alias

# confirmed friends
func load_friends() -> void:
	var options := Talo.player_relationships.GetSubscriptionsOptions.new()
	options.confirmed = Talo.player_relationships.ConfirmedFilter.CONFIRMED
	var page := await Talo.player_relationships.get_subscriptions(options)
	if not page:
		return 
	_friends.assign(page.subscriptions.map(func (sub: TaloPlayerAliasSubscription): return sub.subscribed_to))

# unconfirmed requests other players have sent to the current player
func load_pending_requests() -> void:
	var options := Talo.player_relationships.GetSubscribersOptions.new()
	options.confirmed = Talo.player_relationships.ConfirmedFilter.UNCONFIRMED
	var page := await Talo.player_relationships.get_subscribers(options)
	if not page:
		return 
	_pending_requests.assign(page.subscriptions.map(func (sub: TaloPlayerAliasSubscription): return sub.subscriber))
# unconfirmed requests the current player has sent
func load_outgoing_requests() -> void:
	var options := Talo.player_relationships.GetSubscriptionsOptions.new()
	options.confirmed = Talo.player_relationships.ConfirmedFilter.UNCONFIRMED
	var page := await Talo.player_relationships.get_subscriptions(options)
	if not page:
		return 
	_outgoing_requests.assign(page.subscriptions.map(func (sub: TaloPlayerAliasSubscription): return sub.subscribed_to))

func get_friends() -> Array[TaloPlayerAlias]:
	return _friends

func get_pending_requests() -> Array[TaloPlayerAlias]:
	return _pending_requests

func get_outgoing_requests() -> Array[TaloPlayerAlias]:
	return _outgoing_requests

func accept_friend_request(alias: TaloPlayerAlias) -> bool:
	return await Talo.player_relationships.confirm_subscription_from(alias.id)

func remove_friend(alias: TaloPlayerAlias) -> bool:
	return await Talo.player_relationships.unsubscribe_from(alias.id)

func refresh_all_data() -> void:
	await load_friends()
	await load_outgoing_requests()
	await load_pending_requests()


func _on_accept_pressed():
	accept_friend_request(show_accept_friend_request_popup_alias)
	$PopupGray.hide()
	$"PopupGray/Panel/accept friend".hide()


func _on_decline_pressed():
	remove_friend(show_accept_friend_request_popup_alias)
	$PopupGray.hide()
	$"PopupGray/Panel/accept friend".hide()


func _on_send_pressed():#
	if $LineEdit.text == "":
		return
	print($LineEdit.text + "[//*&MPersom:" + current_friend.identifier + ":M&*//]")
	Talo.player_relationships.broadcast($LineEdit.text + "[//*&MPersom:" + current_friend.identifier + ":M&*//]")
	Talo.leaderboards.add_entry("friends_message_storage",int(Time.get_datetime_string_from_system()),{"message": $LineEdit.text,"from" : account.usrn,"to" : current_friend.identifier})
	await get_tree().create_timer(1).timeout
	$LineEdit.text = ""


func _input(event):
	if Input.is_action_just_pressed("non-send enter"):
		return
	if $LineEdit.has_focus() && Input.is_key_pressed(KEY_ENTER):
		_on_send_pressed()
