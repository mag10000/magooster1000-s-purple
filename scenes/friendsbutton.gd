extends Button

var type = "friend"
var talo_alias = null

# Called when the node enters the scene tree for the first time.
func _ready():
	text = talo_alias.identifier
	print(type + " ",talo_alias)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	if type == "request":
		$"../../../../..".show_accept_friend_request_popup(talo_alias)
	if type == "friend":
		$"../../../../..".switch_to_friend(talo_alias)
