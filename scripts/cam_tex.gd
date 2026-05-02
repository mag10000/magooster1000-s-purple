extends TextureRect
@onready var camera_choice_button = $"../bar/HBoxContainer/OptionButton"

var camera_name = "Microsoft® LifeCam Cinema(TM)"
var camera: CameraFeed
var cameras : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	var camera_extension := CameraServerExtension.new()
	# Check camera permission
	if camera_extension.permission_granted():
		# All good
		print("connected")
	else:
		var _on_permission_result = func(granted: bool) -> void:
			if not granted:
				print("Camera access permission not granted")
				return
		camera_extension.permission_result.connect(_on_permission_result)
		camera_extension.request_permission()
	# Check new camera feeds
	CameraServer.set_monitoring_feeds(true)
	print("cameras:")
	cameras = CameraServer.feeds()
	for feed in CameraServer.feeds():
		var _name = feed.get_name()
		print(_name)
		camera_choice_button.add_item(_name,feed.get_id())
		camera_choice_button.selected = feed.get_id()
		if camera == null and _name == camera_name:
			camera = feed
	
	if camera == null:
		print("no matching camera")
		return
	
	print("using camera ", camera," (",camera.get_name(),")")
	
	camera.feed_is_active = true
	
	camera._activate_feed()
	var image = Image.new()
	camera.set_ycbcr_image(image)
	
	var image_texture = ImageTexture.new()
	image_texture.set_image(image)
	
	texture = image_texture

func _process(delta):
	#camera_name = $"../bar/HBoxContainer/OptionButton"
	var id = camera_choice_button.selected
	camera_name = camera_choice_button.get_item_text(id)
