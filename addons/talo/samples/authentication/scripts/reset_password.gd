extends Node2D

signal password_reset_success
signal go_to_forgot_password

@onready var code: TextEdit = %Code
@onready var new_password: TextEdit = %NewPassword
@onready var validation_label: Label = %ValidationLabel

func _on_submit_pressed() -> void:
	validation_label.text = ""

	if not code.text:
		validation_label.text = tr("Code is required")
		return

	if not new_password.text:
		validation_label.text = tr("New password is required")
		return

	var res := await Talo.player_auth.reset_password(code.text, new_password.text)
	if res != OK:
		match Talo.player_auth.last_error.get_code():
			TaloAuthError.ErrorCode.PASSWORD_RESET_CODE_INVALID:
				validation_label.text = tr("Reset code is invalid")
			_:
				validation_label.text = tr(Talo.player_auth.last_error.get_string())
	else:
		password_reset_success.emit()

func _on_cancel_pressed() -> void:
	go_to_forgot_password.emit()

func _process(delta):
	if account.dark_or_light == "dark":
		$UI/Background.color = account.dark_bg
		$UI/MarginContainer.theme = load("res://main theme.tres")
	else:
		$UI/Background.color = account.light_bg
		$UI/MarginContainer.theme = load("res://main theme light.tres")
