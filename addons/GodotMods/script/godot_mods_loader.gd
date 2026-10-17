extends Node

const MOD_DIR_NAME := "mods";

func _init() -> void:
	var dirs: Array[String] = []
	dirs.append("user://%s" % MOD_DIR_NAME)

	var exe_dir := OS.get_executable_path().get_base_dir();
	dirs.append(exe_dir.path_join(MOD_DIR_NAME));

	for dir in dirs:
		_load_pcks_from_dir(dir);

func _load_pcks_from_dir(dir_path: String) -> void:
	if(!DirAccess.dir_exists_absolute(dir_path)): return;

	var files := DirAccess.get_files_at(dir_path);
	files.sort();

	for file in files:
		if(!file.to_lower().ends_with(".pck")): continue;
		var pck_path := dir_path.path_join(file);
		var ok := ProjectSettings.load_resource_pack(pck_path, true);
		if(ok):
			print("[GodotMods] Loaded mod PCK: ", pck_path)
		else:
			print("[GodotMods] Failed to load mod PCK: " + pck_path)
		for file2 in DirAccess.get_directories_at("res://"):
			print(file2)
