extends Node2D

signal verification_required
signal go_to_forgot_password
signal go_to_register

@onready var username: TextEdit = %Username
@onready var password: TextEdit = %Password
@onready var validation_label: Label = %ValidationLabel

func _on_submit_pressed() -> void:
	validation_label.text = ""

	if not username.text:
		validation_label.text = tr("Username is required")
		return

	if not password.text:
		validation_label.text = tr("Password is required")
		return

	var res := await Talo.player_auth.login(username.text, password.text)
	match res:
		Talo.player_auth.LoginResult.FAILED:
			match Talo.player_auth.last_error.get_code():
				TaloAuthError.ErrorCode.INVALID_CREDENTIALS:
					validation_label.text = tr("Username or password is incorrect")
				_:
					validation_label.text = tr(Talo.player_auth.last_error.get_string())
		Talo.player_auth.LoginResult.VERIFICATION_REQUIRED:
			verification_required.emit()
		Talo.player_auth.LoginResult.OK:
			account.usrn = username.text
			account.logged_in = true
			account.talo_save(password.text,username.text)

func _on_forgot_password_pressed() -> void:
	go_to_forgot_password.emit()

func _on_register_pressed() -> void:
	go_to_register.emit()

func _process(delta):
	%Verify.username = username.text
	
	if account.dark_or_light == "dark":
		$UI/Background.color = account.dark_bg
		$UI/MarginContainer.theme = load("res://main theme.tres")
	else:
		$UI/Background.color = account.light_bg
		$UI/MarginContainer.theme = load("res://main theme light.tres")
