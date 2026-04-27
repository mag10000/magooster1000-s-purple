extends Control

@onready var email_label: RichTextLabel = $SignedInPanel/VBoxContainer/email
@onready var user_id_label: RichTextLabel = $SignedInPanel/VBoxContainer/userid
@onready var sign_in_button: Button = $LoginPanel/SignInButton
@onready var sign_out_button: Button = $SignedInPanel/VBoxContainer/SignoutButtonContainer/SignOutButton
@onready var LoginPanel: PanelContainer = $LoginPanel
@onready var SignedInPanel: PanelContainer = $SignedInPanel
var authed = false

func _ready() -> void:
	SupabaseAuth.auth_success.connect(_on_auth_success)
	SupabaseAuth.auth_error.connect(_on_auth_error)
	
	_check_existing_session()


func _on_auth_success(session: Dictionary):
	_show_authenticated_ui(session)

func _on_auth_error(_error: String):
	_show_login_ui()


func _check_existing_session():
	var session = SupabaseAuth.load_session()
	if session.has("access_token") and session.access_token != "":
		if _is_token_expired(session):
			print("Session expired, need to login again")
			if session.has("refresh_token") and session.refresh_token != "":
				SupabaseAuth.refresh_token(session.refresh_token)
			else:
				_show_login_ui()
		else:
			_show_authenticated_ui(session)
	else:
		_show_login_ui()

func _is_token_expired(session: Dictionary) -> bool:
	if not session.has("expires_in"):
		return false 
	
	var file_path = "user://auth_session.dat"
	if FileAccess.file_exists(file_path):
		var file_time = FileAccess.get_modified_time(file_path)
		var current_time = Time.get_unix_time_from_system()
		var age = current_time - file_time
		
		return age > (session.expires_in - 300)
	
	return false


func _show_login_ui():
	# Show login button
	LoginPanel.visible = true
	sign_in_button.disabled = false
	sign_in_button.text = tr("Sign in with Google")

	$LoginPanelDiscord.visible = true
	$LoginPanelDiscord/SignInButtonDiscord.disabled = false
	$LoginPanelDiscord/SignInButtonDiscord.text = tr("Sign in with Discord")
	$SignedInPanel/VBoxContainer/avatar/AnimatedSprite2D.show()
	$SignedInPanel/VBoxContainer/avatar.texture = null
	
	$LoginPanelEmail.visible = true
	$LoginPanelEmail/SignInButtonEmail.disabled = false
	$LoginPanelEmail/SignInButtonEmail.text = tr("Sign in with Email")
	
	
	# Hide user info panel
	SignedInPanel.visible = false

var session_globe = null
var user_globe = null
var name_globe = null

func _show_authenticated_ui(session: Dictionary):
	session_globe = session
	
	# Hide login button
	LoginPanel.visible = false
	sign_in_button.disabled = true
	
	# Show user info panel with sign out button
	SignedInPanel.visible = true
	
	authed = true
	
	var user = session.get("user", {})
	email_label.text = tr("Email: ") + user.get("email", "Unknown")
	user_id_label.text = tr("User ID: ") + user.get("id", "Unknown")
	
	user_globe = user
	
	var ident = user.identities[0].identity_data
	print(ident)
	
	var _name = "UNREGISTERED"
	
	if ident.has("custom_claims"):
		var claims = ident.custom_claims
		if claims.has("global_name"):
			$SignedInPanel/VBoxContainer/username.text = tr("Name: ") + claims.global_name
			_name = claims.global_name
		else:
			if ident.has("full_name"):
				$SignedInPanel/VBoxContainer/username.text = tr("Name: ") + ident.full_name
				_name = ident.full_name
			elif ident.has("name"):
				$SignedInPanel/VBoxContainer/username.text = tr("Name: ") + ident.name
				_name = ident.name
	else:
		if ident.has("full_name"):
			$SignedInPanel/VBoxContainer/username.text = tr("Name: ") + ident.full_name
			_name = ident.full_name
		elif ident.has("name"):
			$SignedInPanel/VBoxContainer/username.text = tr("Name: ") + ident.name
			_name = ident.name
	
	if ident.has("avatar_url"):
		avatar(ident.avatar_url)
	name_globe = _name
	
	await get_tree().create_timer(2).timeout
	Talo.players.identify(SupabaseAuth.provider,_name)
	Talo.players.identified.connect(identified)


func identified(player):
	var user = user_globe
	var _name = name_globe
	
	account.logged_in = true
	account.usrn = _name
	print("logged in:",account.logged_in," usrn:",account.usrn)
	$Authentication.show()
	
	
	Talo.events.track("Supabase Auth", {
		"Time": str(Time.get_time_string_from_system()),
		"Id" : user.get("id", "Unknown"),
		"Email" : user.get("email", "Unknown"),
		"Name" : _name,
		"Service" : SupabaseAuth.provider
	})
	Talo.events.flush()
	Talo.channels.get_channels()



func create_channel(_name):
	var options := Talo.channels.CreateChannelOptions.new()
	options.name = _name
	options.auto_cleanup = false
	options.props = {
		prop_key = "prop_value"
	}
	var channel := await Talo.channels.create(options)
	account.channel_id = channel.id

func _on_sign_in_button_pressed() -> void:
	sign_in_button.disabled = true
	sign_in_button.text = tr("Opening browser for authentication...")
	
	SupabaseAuth.provider = "google"
	SupabaseAuth.sign_in_with_google()


func _on_sign_out_button_pressed() -> void:
	authed = false
	SupabaseAuth.sign_out()
	Talo.player_auth.logout()
	_show_login_ui()


func _on_sign_in_button_discord_pressed():
	$LoginPanelDiscord/SignInButtonDiscord.disabled = true
	$LoginPanelDiscord/SignInButtonDiscord.text = tr("Opening browser for authentication...")
	
	SupabaseAuth.provider = "discord"
	SupabaseAuth.sign_in_with_google()

var url = ""
func avatar(url_):
	url = url_
	print(url)
	$avatarrequest.request(url_)


func _on_avatarrequest_request_completed(result, response_code, headers, body):
	var _name = url.replace(".png","").replace("https://","").replace("/","")
	if FileAccess.file_exists("user://" + _name +".png"):
		var image = Image.new()
		image.load("user://" + _name +".png")
		
		var image_texture = ImageTexture.new()
		image_texture.set_image(image)
		
		$SignedInPanel/VBoxContainer/avatar.texture = image_texture
		$SignedInPanel/VBoxContainer/avatar/AnimatedSprite2D.hide()
	var file = FileAccess.open("user://" + _name +".png", FileAccess.WRITE)
	file.store_buffer(body)
	file.close()
	file = null
	var image = Image.new()
	image.load("user://" + _name +".png")
	
	var image_texture = ImageTexture.new()
	image_texture.set_image(image)
	
	$SignedInPanel/VBoxContainer/avatar.texture = image_texture
	$SignedInPanel/VBoxContainer/avatar/AnimatedSprite2D.hide()


func _on_sign_in_button_email_pressed():
	$Authentication.show()

func _process(delta):
	if $Authentication.visible:
		$MpText2.show()
	else:
		$MpText2.hide()
	
	if account.dark_or_light == "dark":
		$BG.color = account.dark_bg
		$LoginPanel.theme = load("res://main theme.tres")
		$LoginPanelDiscord.theme = load("res://main theme.tres")
		$LoginPanelEmail.theme = load("res://main theme.tres")
		$SignedInPanel.theme = load("res://main theme.tres")
	else:
		$BG.color = account.light_bg
		$LoginPanel.theme = load("res://main theme light.tres")
		$LoginPanelDiscord.theme = load("res://main theme light.tres")
		$LoginPanelEmail.theme = load("res://main theme light.tres")
		$SignedInPanel.theme = load("res://main theme light.tres")
