extends Control

var mod_io_api_key = "a5228f34694e9d7c23b8b8ea85e8dc33"
var mod_io_game_id = 13166
var available_mods = {}
@onready var http_request = $HTTPRequest
var fs = DirAccess

func _ready():
	get_mod_io_list()


func get_mod_io_list():
	var error = http_request.request("https://g-%s.modapi.io/v1/games/%s/mods?api_key=%s" % [mod_io_game_id, mod_io_game_id, mod_io_api_key])
	if error != OK:
		print("An error occurred in the HTTP request. %s" % error)
		print("An error occurred in the HTTP request")


func _http_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		print("get mod.io list error: %d" % response_code)
		return
	
	var parsed_response = JSON.parse_string(body.get_string_from_utf8())
	
	available_mods = []
	for raw_mod in parsed_response.data:
		var mod = {}
		mod.name = raw_mod.name
		mod.profile_url = raw_mod.profile_url
		mod.author = raw_mod.submitted_by.username
		mod.modfile_url = raw_mod.modfile.download.binary_url
		mod.modfile_name = raw_mod.modfile.filename
		mod.modfile_version = raw_mod.modfile.version
		available_mods.append(mod)
		
	print("get_mod_io_list available mods: %s" % JSON.stringify(available_mods))
	create_mod_boxes()


func create_mod_boxes():
	for child in $ModPanel/MainVbox/ModScroll/ModVbox.get_children():
		child.queue_free()
	for mod in available_mods:
		var mod_box_scene = preload("res://scenes/mod_box.tscn")
		var mod_box = mod_box_scene.instantiate()
		mod_box.title = mod.name
		mod_box.download_url = mod.modfile_url
		mod_box.author = mod.author
		mod_box.discription = "Mod version: " + mod.modfile_version + ", File: " + mod.modfile_name
		mod_box.page_url = mod.profile_url
		mod_box.file_name = mod.modfile_name
		$ModPanel/MainVbox/ModScroll/ModVbox.add_child(mod_box)


func download_mod(url : String, node = null):
	var mod_name = node.title
	$ModInstall/ModInstallPanel/Title.text = "[b]Downloading " + mod_name + "..."
	$ModInstall.show()
	DirAccess.make_dir_absolute("user://mods")
	$DownloadRequest.download_file = "user://mods/" + node.file_name.replace(".zip",".pck")
	var file = FileAccess.open("user://mods/" + node.file_name, FileAccess.WRITE)
	file.store_string("")
	file.close()
	file = null
	var extension = node.file_name.get_extension()
	$DownloadRequest.request(node.download_url)




func _on_title_meta_clicked(meta):
	OS.shell_open(meta)


func read_mod_dir(path):
	print("read_mod_dir: " + path)
	var mod_files = DirAccess.get_files_at(path)
	
	for filename in mod_files:
		var extension = filename.get_extension()
		if extension == "pck":
			load_mod(path, filename)

func load_mod(path, filename):
	print("load_mod: " + filename)
	
	var result = ProjectSettings.load_resource_pack(path + filename)
	if not result:
		print("load_mod error for %s" % filename)
		return


func _on_download_request_request_completed(result, response_code, headers, body):
	read_mod_dir("user://mods")


func _on_open_folder_pressed():
	DirAccess.make_dir_absolute("user://mods")
	OS.shell_open(OS.get_user_data_dir() + "/mods")
	
