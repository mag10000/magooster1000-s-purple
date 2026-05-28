extends Control

var friends = []
var outgoing_friends = []
var requests = []

#var presence := await Talo.player_presence.get_presence(player_id)
func _ready():
	if account.logged_in:
		var res := await Talo.player_presence.update_presence(true)
	$FriendsPanel/VBoxContainer/ScrollContainer/VBoxContainer/Button.queue_free()
	$RichTextLabel.text = ""
	Talo.player_presence.presence_changed.connect(_on_presence_changed)


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
	friends = await FriendsManager.load_friends()
	outgoing_friends = await FriendsManager.load_outgoing_requests()
	requests = await FriendsManager.load_pending_requests()
	if not friends.size() > 0:
		$FriendsPanel/VBoxContainer/FriendsLabel.hide()
		$FriendsPanel/VBoxContainer/friends.hide()

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
	else:
		var text = $"PopupGray/Panel/add friend/friend_usrnm".text
		Console.printerr("Failed to send request to %s" % alias.identifier,)
		$"PopupGray/Panel/add friend/friend_usrnm".add_theme_color_override("font_color",Color.RED)
		$"PopupGray/Panel/add friend/friend_usrnm".text = "ERROR"
		await get_tree().create_timer(2).timeout
		$"PopupGray/Panel/add friend/friend_usrnm".add_theme_color_override("font_color",Color.WHITE)
		$"PopupGray/Panel/add friend/friend_usrnm".text = text


func _on_close_pressed():
	$PopupGray.hide()
	$"PopupGray/Panel/add friend".hide()
