extends Control

var friends = []
var outgoing_friends = []
var requests = []
var _friends: Array[TaloPlayerAlias] = []
var _pending_requests: Array[TaloPlayerAlias] = []
var _outgoing_requests: Array[TaloPlayerAlias] = []

#var presence := await Talo.player_presence.get_presence(player_id)
func _ready():
	if account.logged_in:
		var res := await Talo.player_presence.update_presence(true)
	else:
		return
	$RichTextLabel.text = ""
	Talo.player_presence.presence_changed.connect(_on_presence_changed)
	update_friends()
	$FriendsPanel/VBoxContainer/friends/VBoxContainer/Button.queue_free()
	$FriendsPanel/VBoxContainer/pending/VBoxContainer/Button.queue_free()
	$FriendsPanel/VBoxContainer/requests/VBoxContainer/Button.queue_free()


func _process(delta):
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

func update_friends():
	var test = await Talo.player_relationships.get_subscriptions()
	print(test.subscriptions[0].subscriber.identifier)
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
	Console.print(str(requests) + ", " + str(outgoing_friends) + ", " + str(friends))
	for f in friends:
		pass
	for p in outgoing_friends:
		pass
	for r in requests:
		pass
	await get_tree().create_timer(5).timeout
	update_friends()

func _on_attribution_meta_clicked(meta):
	OS.shell_open(meta)

func _on_presence_changed(presence: TaloPlayerPresence, online_changed: bool, custom_status_changed: bool) -> void:
	# check if this player is in our friends list
	if friends.has(presence.player_alias.id):
		if online_changed:
			if presence.online:
				Console.print("%s is now online" % presence.player_alias.identifier)
			else:
				Console.print("%s is now offline" % presence.player_alias.identifier)
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

# confirmed friends
func load_friends() -> void:
	var options := Talo.player_relationships.GetSubscriptionsOptions.new()
	options.confirmed = Talo.player_relationships.ConfirmedFilter.CONFIRMED
	var page := await Talo.player_relationships.get_subscriptions(options)
	_friends.assign(page.subscriptions.map(func (sub: TaloPlayerAliasSubscription): return sub.subscribed_to))

# unconfirmed requests other players have sent to the current player
func load_pending_requests() -> void:
	var options := Talo.player_relationships.GetSubscribersOptions.new()
	options.confirmed = Talo.player_relationships.ConfirmedFilter.UNCONFIRMED
	var page := await Talo.player_relationships.get_subscribers(options)
	_pending_requests.assign(page.subscriptions.map(func (sub: TaloPlayerAliasSubscription): return sub.subscriber))
# unconfirmed requests the current player has sent
func load_outgoing_requests() -> void:
	var options := Talo.player_relationships.GetSubscriptionsOptions.new()
	options.confirmed = Talo.player_relationships.ConfirmedFilter.UNCONFIRMED
	var page := await Talo.player_relationships.get_subscriptions(options)
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
