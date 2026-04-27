extends Node2D

@onready var code: TextEdit = %Code
@onready var validation_label: Label = %ValidationLabel
var username = ""

func _on_submit_pressed() -> void:
	validation_label.text = ""

	if not code.text:
		validation_label.text = tr("Verification code is required")
		return

	var res := await Talo.player_auth.verify(code.text)
	if res != OK:
		match Talo.player_auth.last_error.get_code():
			TaloAuthError.ErrorCode.VERIFICATION_CODE_INVALID:
				validation_label.text = tr("Verification code is incorrect")
			TaloAuthError.ErrorCode.VERIFICATION_ALIAS_NOT_FOUND:
				validation_label.text = tr("Verification session is invalid")
			_:
				validation_label.text = tr(Talo.player_auth.last_error.get_string())
	else:
		account.usrn = username
		account.logged_in = true

func _process(delta):
	if account.dark_or_light == "dark":
		$UI/Background.color = account.dark_bg
		$UI/MarginContainer.theme = load("res://main theme.tres")
	else:
		$UI/Background.color = account.light_bg
		$UI/MarginContainer.theme = load("res://main theme light.tres")
