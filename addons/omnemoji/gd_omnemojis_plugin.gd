@tool
extends EditorPlugin
## gd-OmnEmoji - Universal cross-platform emoji support for Godot
##
## This plugin automatically injects an emoji fallback font into the project,
## ensuring consistent emoji rendering across all platforms (Desktop, Mobile, Web).
##
## Usage: Simply enable the plugin. No configuration required.
## Configuration: See Project Settings → OmnEmoji for optional font customization.

const PLUGIN_NAME := "OmnEmoji"
const PLUGIN_VERSION := ""
const ADDON_PATH := "res://addons/omnemoji/"

# Font providers and downloader
const FontDownloader := preload("res://addons/omnemoji/font_downloader.gd")

# Generated resources - intermediate files go in .cache (hidden from Godot via .gdignore)
# Only OmnEmojiMerged.tres is exposed to Godot for export
const CACHE_PATH := ADDON_PATH + "resources/.cache/"
const EMOJI_FONT_RESOURCE := CACHE_PATH + "OmnEmojiFont.tres"
const TEXT_FONT_RESOURCE := CACHE_PATH + "OmnTextFont.tres"
const MERGED_FONT_RESOURCE := ADDON_PATH + "resources/OmnEmojiMerged.tres"

# Project Settings paths (visible in Project → Project Settings → OmnEmoji)
const SETTING_PREFIX := "omnemoji/"
const SETTING_ENABLED := SETTING_PREFIX + "enabled"
const SETTING_EMOJI_PROVIDER := SETTING_PREFIX + "emoji_provider"
const SETTING_TEXT_PROVIDER := SETTING_PREFIX + "text_provider"
const SETTING_AUTO_DOWNLOAD := SETTING_PREFIX + "auto_download"
const SETTING_EMOJI_FONT := SETTING_PREFIX + "custom_emoji_font"
const SETTING_TEXT_FONT := SETTING_PREFIX + "custom_text_font"
const BACKUP_FONT_SETTING := SETTING_PREFIX + "backup_font"
const CUSTOM_FONT_SETTING := "gui/theme/custom_font"

var _export_plugin: EditorExportPlugin = null
var _downloader: Node = null  # FontDownloader instance
var _download_in_progress := false
var _download_queue: Array[Dictionary] = []  # Queue of {provider_id, is_emoji}
var _rebuilding := false  # Guard against infinite loops
var _last_applied_config := ""  # Track last applied configuration hash
var _pending_initialization := false  # Wait for downloads before init


func _enter_tree() -> void:
	# Register project settings (always do this first)
	_register_project_settings()
	
	# Create the font downloader node
	_downloader = FontDownloader.new()
	_downloader.name = "OmnEmojiFontDownloader"
	_downloader.download_completed.connect(_on_download_completed)
	add_child(_downloader)
	
	# Check if plugin is enabled in settings
	if not _is_enabled():
		print("[OmnEmoji] Plugin disabled in Project Settings.")
		return
	
	# Check and download missing fonts if auto-download enabled
	if not _verify_fonts_exist():
		if _is_auto_download_enabled():
			print("[OmnEmoji] Missing fonts detected, starting downloads...")
			_pending_initialization = true
			_start_missing_font_downloads()
			return  # Initialization will continue when downloads complete
		else:
			push_error("[OmnEmoji] Required fonts missing! Enable auto-download or configure manually.")
			push_error("[OmnEmoji] Project Settings → OmnEmoji → Auto Download Missing Fonts")
			return
	
	# Fonts exist, proceed with initialization
	_complete_initialization()


func _exit_tree() -> void:
	# Disconnect settings signal
	if ProjectSettings.settings_changed.is_connected(_on_settings_changed):
		ProjectSettings.settings_changed.disconnect(_on_settings_changed)
	
	# Remove downloader
	if _downloader:
		_downloader.queue_free()
		_downloader = null
	
	# Unregister export plugin
	if _export_plugin:
		remove_export_plugin(_export_plugin)
		_export_plugin = null
	
	print("[OmnEmoji] Plugin disabled.")


## Complete initialization after fonts are ready
func _complete_initialization() -> void:
	# Create font resources if needed
	_ensure_font_resources()
	
	# Check if we're already configured - be quiet if so
	if _is_already_configured():
		# Already configured - just show a quiet status line
		var emoji_id := _get_emoji_provider_id()
		var text_id := _get_text_provider_id()
		var emoji_name := "System"
		var text_name := "System"
		
		if emoji_id != "":
			var ep := OmnEmojiFontProviders.get_emoji_provider(emoji_id)
			emoji_name = ep.get("name", emoji_id) if ep else emoji_id
		elif _get_emoji_provider_selection() == 0:
			emoji_name = "Custom"
		
		if text_id != "":
			var tp := OmnEmojiFontProviders.get_text_provider(text_id)
			text_name = tp.get("name", text_id) if tp else text_id
		elif _get_text_provider_selection() == 0:
			text_name = "Custom"
		
		print("[OmnEmoji] ✓ Ready — %s + %s" % [emoji_name, text_name])
		_last_applied_config = _get_config_hash()
	else:
		# Need to build/rebuild fonts
		_apply_emoji_fallback()
	
	# Register export plugin to ensure fonts are bundled
	_register_export_plugin()
	
	# Watch for settings changes
	if not ProjectSettings.settings_changed.is_connected(_on_settings_changed):
		ProjectSettings.settings_changed.connect(_on_settings_changed)


#region Project Settings

## Register OmnEmoji settings in Project Settings
func _register_project_settings() -> void:
	# Build emoji provider dropdown options
	var emoji_options := PackedStringArray(["Custom File", "System Default"])
	emoji_options.append_array(OmnEmojiFontProviders.get_emoji_provider_labels())
	
	# Build text provider dropdown options  
	var text_options := PackedStringArray(["Custom File", "System Default"])
	text_options.append_array(OmnEmojiFontProviders.get_text_provider_labels())
	
	# 1. Enabled - Main toggle (most important)
	_add_setting(
		SETTING_ENABLED,
		true,
		TYPE_BOOL,
		PROPERTY_HINT_NONE,
		""
	)
	
	# 2. Emoji Provider - Primary emoji font selection
	_add_setting(
		SETTING_EMOJI_PROVIDER,
		2,  # Default to first provider (noto)
		TYPE_INT,
		PROPERTY_HINT_ENUM,
		",".join(emoji_options)
	)
	
	# 3. Text Provider - Primary text font selection
	_add_setting(
		SETTING_TEXT_PROVIDER,
		2,  # Default to first provider (noto_sans)
		TYPE_INT,
		PROPERTY_HINT_ENUM,
		",".join(text_options)
	)
	
	# 4. Auto Download - Download missing fonts automatically
	_add_setting(
		SETTING_AUTO_DOWNLOAD,
		true,
		TYPE_BOOL,
		PROPERTY_HINT_NONE,
		""
	)
	
	# 5. Custom Emoji Font - Path (only used when provider = Custom)
	_add_setting(
		SETTING_EMOJI_FONT,
		"",
		TYPE_STRING,
		PROPERTY_HINT_FILE,
		"*.ttf,*.otf,*.woff,*.woff2"
	)
	
	# 6. Custom Text Font - Path (only used when provider = Custom)
	_add_setting(
		SETTING_TEXT_FONT,
		"",
		TYPE_STRING,
		PROPERTY_HINT_FILE,
		"*.ttf,*.otf,*.woff,*.woff2"
	)
	
	# 9. Backup font (internal, hidden from basic view)
	if not ProjectSettings.has_setting(BACKUP_FONT_SETTING):
		ProjectSettings.set_setting(BACKUP_FONT_SETTING, "")
	ProjectSettings.set_initial_value(BACKUP_FONT_SETTING, "")
	ProjectSettings.add_property_info({
		"name": BACKUP_FONT_SETTING,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
	})
	# Don't set as basic - hide from default view
	ProjectSettings.set_as_basic(BACKUP_FONT_SETTING, false)


## Add a project setting with proper metadata
func _add_setting(path: String, default_value: Variant, type: int, hint: int, hint_string: String) -> void:
	if not ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, default_value)
	
	ProjectSettings.set_initial_value(path, default_value)
	
	var property_info := {
		"name": path,
		"type": type,
		"hint": hint,
		"hint_string": hint_string,
	}
	
	ProjectSettings.add_property_info(property_info)
	ProjectSettings.set_as_basic(path, true)


## Check if plugin is enabled
func _is_enabled() -> bool:
	return ProjectSettings.get_setting(SETTING_ENABLED, true)


## Check if auto-download is enabled
func _is_auto_download_enabled() -> bool:
	return ProjectSettings.get_setting(SETTING_AUTO_DOWNLOAD, true)


## Handle settings changes
func _on_settings_changed() -> void:
	# Skip if we're in the middle of rebuilding or downloading
	if _rebuilding or _download_in_progress:
		return
	
	# Only process if config actually changed
	var current_config := _get_config_hash()
	if current_config == _last_applied_config:
		return
	
	if _is_enabled():
		# Use call_deferred to avoid issues during settings panel updates
		call_deferred("_apply_font_change")


## Apply font changes with download support and user feedback
func _apply_font_change() -> void:
	# Prevent re-entrant calls
	if _rebuilding or _download_in_progress:
		return
	
	var emoji_id := _get_emoji_provider_id()
	var text_id := _get_text_provider_id()
	
	# Get provider names for feedback
	var emoji_name := "System Default"
	var text_name := "System Default"
	if emoji_id != "":
		var ep := OmnEmojiFontProviders.get_emoji_provider(emoji_id)
		emoji_name = ep.get("name", emoji_id) if ep else emoji_id
	elif _get_emoji_provider_selection() == 0:
		emoji_name = "Custom File"
	
	if text_id != "":
		var tp := OmnEmojiFontProviders.get_text_provider(text_id)
		text_name = tp.get("name", text_id) if tp else text_id
	elif _get_text_provider_selection() == 0:
		text_name = "Custom File"
	
	# Check if we need to download fonts - use async downloader
	var need_downloads := false
	_download_queue.clear()
	
	if emoji_id != "" and not OmnEmojiFontProviders.is_emoji_font_installed(emoji_id):
		need_downloads = true
		var ep := OmnEmojiFontProviders.get_emoji_provider(emoji_id)
		var size: float = ep.get("size_mb", 0.0) if ep else 0.0
		print("[OmnEmoji] ⬇ Downloading %s (~%.1f MB)..." % [emoji_name, size])
		_download_queue.append({"provider_id": emoji_id, "is_emoji": true})
	
	if text_id != "" and not OmnEmojiFontProviders.is_text_font_installed(text_id):
		need_downloads = true
		var tp := OmnEmojiFontProviders.get_text_provider(text_id)
		var size: float = tp.get("size_mb", 0.0) if tp else 0.0
		print("[OmnEmoji] ⬇ Downloading %s (~%.1f MB)..." % [text_name, size])
		_download_queue.append({"provider_id": text_id, "is_emoji": false})
	
	# Start async downloads if needed
	if need_downloads:
		_download_in_progress = true
		_pending_initialization = false  # This is a settings change, not init
		_process_download_queue()
		return  # Will continue in _on_download_completed -> rebuild
	
	# No downloads needed - apply immediately
	if not _verify_fonts_exist():
		push_error("[OmnEmoji] ✗ Required fonts still missing!")
		return
	
	# Rebuild the merged font (provides all feedback)
	rebuild_fallback()


## Generate a hash of current font configuration to detect real changes
func _get_config_hash() -> String:
	return "%d:%d:%s:%s" % [
		_get_emoji_provider_selection(),
		_get_text_provider_selection(),
		ProjectSettings.get_setting(SETTING_EMOJI_FONT, ""),
		ProjectSettings.get_setting(SETTING_TEXT_FONT, ""),
	]


## Check if fonts are already properly configured and no rebuild is needed
func _is_already_configured() -> bool:
	# Check if merged font resource exists
	if not ResourceLoader.exists(MERGED_FONT_RESOURCE):
		return false
	
	# Check if project is using our merged font
	var current_font: String = ProjectSettings.get_setting(CUSTOM_FONT_SETTING, "")
	if current_font != MERGED_FONT_RESOURCE:
		return false
	
	# Check if config has changed since last apply
	var current_hash := _get_config_hash()
	if _last_applied_config != "" and _last_applied_config != current_hash:
		return false
	
	# Try to load the merged font to verify it's valid
	var merged_font = load(MERGED_FONT_RESOURCE)
	if not merged_font:
		return false
	
	return true

#endregion


#region Font Path Helpers

## Get emoji provider selection (0=Custom, 1=System, 2+=provider index)
func _get_emoji_provider_selection() -> int:
	return ProjectSettings.get_setting(SETTING_EMOJI_PROVIDER, 2)


## Get text provider selection (0=Custom, 1=System, 2+=provider index)
func _get_text_provider_selection() -> int:
	return ProjectSettings.get_setting(SETTING_TEXT_PROVIDER, 2)


## Get the emoji provider ID from selection index
func _get_emoji_provider_id() -> String:
	var selection := _get_emoji_provider_selection()
	if selection < 2:
		return ""  # Custom or System
	var ids := OmnEmojiFontProviders.get_emoji_provider_ids()
	var idx := selection - 2
	if idx >= 0 and idx < ids.size():
		return ids[idx]
	return "noto"  # Fallback


## Get the text provider ID from selection index
func _get_text_provider_id() -> String:
	var selection := _get_text_provider_selection()
	if selection < 2:
		return ""  # Custom or System
	var ids := OmnEmojiFontProviders.get_text_provider_ids()
	var idx := selection - 2
	if idx >= 0 and idx < ids.size():
		return ids[idx]
	return "noto_sans"  # Fallback


## Get the emoji font path based on provider setting
func _get_emoji_font_path() -> String:
	var selection := _get_emoji_provider_selection()
	
	match selection:
		0:  # Custom
			var custom_path: String = ProjectSettings.get_setting(SETTING_EMOJI_FONT, "")
			if custom_path != "" and FileAccess.file_exists(custom_path):
				return custom_path
			push_warning("[OmnEmoji] Custom emoji font not found")
			return ""
		1:  # System
			return ""  # Empty means use system font
		_:  # Provider-based
			var provider_id := _get_emoji_provider_id()
			return OmnEmojiFontProviders.get_emoji_font_path(provider_id)


## Get the text font path based on provider setting
func _get_text_font_path() -> String:
	var selection := _get_text_provider_selection()
	
	match selection:
		0:  # Custom
			var custom_path: String = ProjectSettings.get_setting(SETTING_TEXT_FONT, "")
			if custom_path != "" and FileAccess.file_exists(custom_path):
				return custom_path
			push_warning("[OmnEmoji] Custom text font not found")
			return ""
		1:  # System
			return ""  # Use system default
		_:  # Provider-based
			var provider_id := _get_text_provider_id()
			return OmnEmojiFontProviders.get_text_font_path(provider_id)


## Check if using system emoji (no bundled font)
func _is_using_system_emoji() -> bool:
	return _get_emoji_provider_selection() == 1

#endregion


#region Font Management

## Verify required fonts exist
func _verify_fonts_exist() -> bool:
	# Check emoji font (unless using system)
	if not _is_using_system_emoji():
		var emoji_path := _get_emoji_font_path()
		if emoji_path == "" or not FileAccess.file_exists(emoji_path):
			return false
	
	# Check text font (unless using system)
	if _get_text_provider_selection() != 1:
		var text_path := _get_text_font_path()
		if text_path == "" or not FileAccess.file_exists(text_path):
			# Text font missing is less critical
			push_warning("[OmnEmoji] Text font not found, will attempt download")
			return false
	
	return true


## Start async downloads for missing fonts (builds queue and starts first download)
func _start_missing_font_downloads() -> void:
	_download_queue.clear()
	_download_in_progress = true
	
	# Queue emoji font if needed
	if not _is_using_system_emoji():
		var emoji_id := _get_emoji_provider_id()
		if emoji_id != "" and not OmnEmojiFontProviders.is_emoji_font_installed(emoji_id):
			var ep := OmnEmojiFontProviders.get_emoji_provider(emoji_id)
			var size: float = ep.get("size_mb", 0.0) if ep else 0.0
			print("[OmnEmoji] ⬇ Queued emoji font: %s (~%.1f MB)" % [emoji_id, size])
			_download_queue.append({"provider_id": emoji_id, "is_emoji": true})
	
	# Queue text font if needed
	if _get_text_provider_selection() >= 2:
		var text_id := _get_text_provider_id()
		if text_id != "" and not OmnEmojiFontProviders.is_text_font_installed(text_id):
			var tp := OmnEmojiFontProviders.get_text_provider(text_id)
			var size: float = tp.get("size_mb", 0.0) if tp else 0.0
			print("[OmnEmoji] ⬇ Queued text font: %s (~%.1f MB)" % [text_id, size])
			_download_queue.append({"provider_id": text_id, "is_emoji": false})
	
	# Start processing the queue
	_process_download_queue()


## Process the next item in the download queue
func _process_download_queue() -> void:
	if _download_queue.is_empty():
		_download_in_progress = false
		
		# Check if this was during initialization
		if _pending_initialization:
			_pending_initialization = false
			if _verify_fonts_exist():
				_complete_initialization()
			else:
				push_error("[OmnEmoji] ✗ Fonts still missing after downloads!")
		else:
			# This was a settings change - apply the new fonts
			if _verify_fonts_exist():
				rebuild_fallback()
			else:
				push_error("[OmnEmoji] ✗ Required fonts still missing!")
		return
	
	var item: Dictionary = _download_queue[0]
	var provider_id: String = item.get("provider_id", "")
	var is_emoji: bool = item.get("is_emoji", true)
	
	if is_emoji:
		_downloader.download_emoji_font(provider_id)
	else:
		_downloader.download_text_font(provider_id)


## Handle download completion
func _on_download_completed(result: Dictionary) -> void:
	var status: int = result.get("status", OmnEmojiFontProviders.DownloadStatus.FAILED_NETWORK)
	var message: String = result.get("message", "Unknown error")
	var provider_id: String = result.get("provider_id", "")
	var is_emoji: bool = result.get("is_emoji", true)
	var font_type := "emoji" if is_emoji else "text"
	
	if status == OmnEmojiFontProviders.DownloadStatus.SUCCESS:
		print("[OmnEmoji] ✓ %s font downloaded: %s" % [font_type.capitalize(), provider_id])
	else:
		push_error("[OmnEmoji] ✗ %s download failed: %s" % [font_type.capitalize(), message])
	
	# Remove from queue and process next
	if not _download_queue.is_empty():
		_download_queue.remove_at(0)
	
	_process_download_queue()


## Ensure cache directory exists
func _ensure_cache_dir() -> void:
	var cache_dir := CACHE_PATH.replace("res://", "")
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(CACHE_PATH)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_PATH))
		# Create .gdignore to hide from Godot
		var gdignore_path := CACHE_PATH + ".gdignore"
		if not FileAccess.file_exists(gdignore_path):
			var f := FileAccess.open(gdignore_path, FileAccess.WRITE)
			if f:
				f.close()


## Ensure font resource files exist
func _ensure_font_resources() -> void:
	_ensure_cache_dir()
	
	var emoji_path := _get_emoji_font_path()
	var text_path := _get_text_font_path()
	
	# Create OmnEmojiFont.tres if it doesn't exist
	if not ResourceLoader.exists(EMOJI_FONT_RESOURCE):
		_create_font_resource(emoji_path, EMOJI_FONT_RESOURCE, "emoji")
	
	# Create OmnTextFont.tres if it doesn't exist  
	if FileAccess.file_exists(text_path) and not ResourceLoader.exists(TEXT_FONT_RESOURCE):
		_create_font_resource(text_path, TEXT_FONT_RESOURCE, "text")


## Create a FontFile resource from a TTF
func _create_font_resource(ttf_path: String, resource_path: String, font_type: String) -> void:
	var font := FontFile.new()
	font.load_dynamic_font(ttf_path)
	
	var err := ResourceSaver.save(font, resource_path)
	if err != OK:
		push_error("[OmnEmoji] Failed to create %s font resource: %s" % [font_type, error_string(err)])
	else:
		print("[OmnEmoji] Created %s font resource: %s" % [font_type, resource_path])


## Request Godot to reimport a file (for newly downloaded fonts)
func _request_reimport(res_path: String) -> void:
	# Touch the file to trigger reimport on next editor scan
	var editor_fs := EditorInterface.get_resource_filesystem()
	if editor_fs:
		editor_fs.scan()


## Validate that a font has usable data (prevents "fd is null" errors)
func _is_font_valid(font: FontFile) -> bool:
	if not font:
		return false
	# Check if font has valid data by testing if it can provide font metrics
	# This catches the "fd is null" case where font exists but data isn't loaded
	var ascent := font.get_ascent(16)
	var descent := font.get_descent(16)
	# A valid font should have non-zero ascent
	return ascent > 0.0


## Load a font file, handling both imported and unimported files
func _load_font_file(res_path: String) -> FontFile:
	# Try loading via resource system first (for imported fonts)
	if ResourceLoader.exists(res_path):
		var font = load(res_path) as FontFile
		if font and _is_font_valid(font):
			return font.duplicate() as FontFile
	
	# If resource system fails, try loading directly (for newly downloaded fonts)
	if FileAccess.file_exists(res_path):
		var font := FontFile.new()
		var global_path := ProjectSettings.globalize_path(res_path)
		var err := font.load_dynamic_font(global_path)
		if err == OK and _is_font_valid(font):
			# Request reimport so it works via resource system next time
			_request_reimport(res_path)
			return font
	
	return null


## Apply the emoji fallback font to the project
func _apply_emoji_fallback() -> void:
	# Set rebuilding flag if not already set (direct calls)
	var was_rebuilding := _rebuilding
	_rebuilding = true
	
	# System provider - just use text font without emoji fallback
	if _is_using_system_emoji():
		print("[OmnEmoji] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("[OmnEmoji] 📦 BUNDLING FONTS (System Emoji Mode)")
		print("[OmnEmoji] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("[OmnEmoji]   Using system emoji fonts")
		_apply_text_font_only()
		_last_applied_config = _get_config_hash()
		print("[OmnEmoji] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("[OmnEmoji] ✓ BUNDLING COMPLETE")
		print("[OmnEmoji] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		if not was_rebuilding:
			_rebuilding = false
		return
	
	var emoji_path := _get_emoji_font_path()
	var text_path := _get_text_font_path()
	var emoji_id := _get_emoji_provider_id()
	var text_id := _get_text_provider_id()
	
	# Get provider info for display
	var emoji_provider := OmnEmojiFontProviders.get_emoji_provider(emoji_id) if emoji_id else {}
	var text_provider := OmnEmojiFontProviders.get_text_provider(text_id) if text_id else {}
	var emoji_name: String = emoji_provider.get("name", "Custom") if emoji_provider else "Custom"
	var text_name: String = text_provider.get("name", "Custom") if text_provider else "Custom"
	var emoji_format: String = emoji_provider.get("format", "TTF") if emoji_provider else "TTF"
	
	# Display bundling header
	print("[OmnEmoji] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("[OmnEmoji] 📦 BUNDLING FONTS")
	print("[OmnEmoji] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("[OmnEmoji]   Emoji: %s (%s)" % [emoji_name, emoji_format])
	print("[OmnEmoji]   Text:  %s" % text_name)
	print("[OmnEmoji] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	
	# Step 1: Load emoji font
	print("[OmnEmoji] [1/4] Loading emoji font...")
	var emoji_font := _load_font_file(emoji_path)
	
	if not emoji_font:
		push_error("[OmnEmoji] ✗ Failed to load emoji font: %s" % emoji_path)
		if not was_rebuilding:
			_rebuilding = false
		return
	print("[OmnEmoji]       ✓ Loaded: %s" % emoji_path.get_file())
	
	# Step 2: Load text font (or use system default)
	print("[OmnEmoji] [2/4] Loading text font...")
	var text_font: FontFile = null
	var using_system_text := false
	
	if text_path != "":
		text_font = _load_font_file(text_path)
		if text_font:
			print("[OmnEmoji]       ✓ Loaded: %s" % text_path.get_file())
	
	if not text_font:
		# No text font specified - use emoji font directly as fallback
		# The system default font will be used as base
		using_system_text = true
		print("[OmnEmoji]       ℹ Using system default text font")
	
	# Get the current custom font (if any)
	var current_font_path: String = ""
	if ProjectSettings.has_setting(CUSTOM_FONT_SETTING):
		current_font_path = ProjectSettings.get_setting(CUSTOM_FONT_SETTING, "")
	
	# Backup current font setting (only if not already backed up)
	if not ProjectSettings.has_setting(BACKUP_FONT_SETTING):
		ProjectSettings.set_setting(BACKUP_FONT_SETTING, current_font_path)
	
	# Step 3: Build merged font
	print("[OmnEmoji] [3/4] Building merged font resource...")
	
	var merged := FontVariation.new()
	
	if using_system_text:
		# No text font - just add emoji as fallback to system font
		# Create a FontVariation that only adds emoji fallback
		merged.fallbacks.append(emoji_font)
		print("[OmnEmoji]       ✓ System font as base")
		print("[OmnEmoji]       ✓ Added %s as emoji fallback" % emoji_name)
	else:
		# Setup fallback chain: text_font -> emoji_font
		text_font.fallbacks.clear()
		text_font.fallbacks.append(emoji_font)
		
		# If there's an existing main font, use it as base
		if current_font_path != "" and current_font_path != MERGED_FONT_RESOURCE and ResourceLoader.exists(current_font_path):
			var main_font = load(current_font_path)
			if main_font is Font:
				merged.base_font = main_font
				if main_font is FontFile:
					main_font.fallbacks.clear()
					main_font.fallbacks.append(text_font)
				elif main_font is FontVariation and main_font.base_font:
					merged.fallbacks.append(text_font)
				print("[OmnEmoji]       ✓ Using existing project font as base")
		else:
			merged.base_font = text_font
			print("[OmnEmoji]       ✓ Using %s as base font" % text_name)
		
		print("[OmnEmoji]       ✓ Added %s as emoji fallback" % emoji_name)
	
	# Step 4: Save resources
	print("[OmnEmoji] [4/4] Saving bundled resources...")
	
	# Save text font with fallbacks (only if we have one)
	if text_font:
		var err := ResourceSaver.save(text_font, TEXT_FONT_RESOURCE)
		if err != OK:
			push_warning("[OmnEmoji]       ⚠ Could not save text font: %s" % error_string(err))
		else:
			print("[OmnEmoji]       ✓ Saved: OmnTextFont.tres")
	
	# Save merged font
	var save_err := ResourceSaver.save(merged, MERGED_FONT_RESOURCE)
	if save_err != OK:
		push_error("[OmnEmoji] ✗ Failed to save merged font: %s" % error_string(save_err))
		if not was_rebuilding:
			_rebuilding = false
		return
	print("[OmnEmoji]       ✓ Saved: OmnEmojiMerged.tres")
	
	# Apply as project default font
	ProjectSettings.set_setting(CUSTOM_FONT_SETTING, MERGED_FONT_RESOURCE)
	ProjectSettings.save()
	print("[OmnEmoji]       ✓ Set as project default font")
	
	# Update config hash after successful apply
	_last_applied_config = _get_config_hash()
	
	if not was_rebuilding:
		_rebuilding = false
	
	# Success summary
	print("[OmnEmoji] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("[OmnEmoji] ✓ BUNDLING COMPLETE")
	print("[OmnEmoji] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")


## Build a merged font with emoji fallback
func _build_merged_font(main_font_path: String, emoji_font: FontFile) -> FontVariation:
	var merged := FontVariation.new()
	
	# Load text font using resource system (properly imported)
	var text_path := _get_text_font_path()
	var text_font: FontFile = null
	
	if ResourceLoader.exists(text_path):
		text_font = load(text_path) as FontFile
		if text_font:
			# Duplicate to avoid modifying the cached resource
			text_font = text_font.duplicate() as FontFile
	
	if not text_font:
		push_error("[OmnEmoji] Text font not found: %s" % text_path)
		return null
	
	# Clear any existing fallbacks and add emoji
	text_font.fallbacks.clear()
	text_font.fallbacks.append(emoji_font)
	
	# Save the text font with its fallbacks
	var err := ResourceSaver.save(text_font, TEXT_FONT_RESOURCE)
	if err != OK:
		push_warning("[OmnEmoji] Could not save text font with fallbacks: %s" % error_string(err))
	
	# If there's an existing main font, use it as base
	if main_font_path != "" and main_font_path != MERGED_FONT_RESOURCE and ResourceLoader.exists(main_font_path):
		var main_font = load(main_font_path)
		if main_font is Font:
			merged.base_font = main_font
			# Add our text+emoji font as fallback to the main font
			if main_font is FontFile:
				main_font.fallbacks.clear()
				main_font.fallbacks.append(text_font)
			elif main_font is FontVariation and main_font.base_font:
				merged.fallbacks.append(text_font)
			return merged
	
	# No main font configured - use our text font directly
	merged.base_font = text_font
	return merged


## Get the text font (using resource system for proper import handling)
func _get_text_font() -> FontFile:
	var text_path := _get_text_font_path()
	
	# Load using resource system to get properly imported font
	if ResourceLoader.exists(text_path):
		var font = load(text_path) as FontFile
		if font:
			return font.duplicate() as FontFile
	
	# Fallback to saved resource
	if ResourceLoader.exists(TEXT_FONT_RESOURCE):
		return load(TEXT_FONT_RESOURCE).duplicate() as FontFile
	
	return null


## Apply text font only (for System provider mode)
func _apply_text_font_only() -> void:
	var text_font := _get_text_font()
	if not text_font:
		print("[OmnEmoji] No text font configured, using Godot defaults")
		return
	
	# Get the current custom font (if any)
	var current_font_path: String = ""
	if ProjectSettings.has_setting(CUSTOM_FONT_SETTING):
		current_font_path = ProjectSettings.get_setting(CUSTOM_FONT_SETTING, "")
	
	# Backup current font setting (only if not already backed up)
	if not ProjectSettings.has_setting(BACKUP_FONT_SETTING):
		ProjectSettings.set_setting(BACKUP_FONT_SETTING, current_font_path)
	
	# Save text font as the merged resource
	var merged := FontVariation.new()
	merged.base_font = text_font
	
	var err := ResourceSaver.save(merged, MERGED_FONT_RESOURCE)
	if err != OK:
		push_error("[OmnEmoji] Failed to save font: %s" % error_string(err))
		return
	
	ProjectSettings.set_setting(CUSTOM_FONT_SETTING, MERGED_FONT_RESOURCE)
	ProjectSettings.save()
	print("[OmnEmoji] Applied text font (system emoji mode).")

#endregion


#region Export Plugin

## Register the export plugin
func _register_export_plugin() -> void:
	_export_plugin = preload("res://addons/omnemoji/exporter/OmnEmojiExport.gd").new()
	add_export_plugin(_export_plugin)
	print("[OmnEmoji] Export plugin registered - fonts will be bundled in all exports.")

#endregion


#region Public API

## Rebuild the merged font (call this if user changes default font)
func rebuild_fallback() -> void:
	# Prevent re-entrant calls
	if _rebuilding:
		return
	_rebuilding = true
	
	# Get the original backup font (before OmnEmoji)
	var original_font_path: String = ""
	if ProjectSettings.has_setting(BACKUP_FONT_SETTING):
		original_font_path = ProjectSettings.get_setting(BACKUP_FONT_SETTING, "")
	
	# Temporarily restore original setting
	ProjectSettings.set_setting(CUSTOM_FONT_SETTING, original_font_path)
	
	# Re-apply emoji fallback (this provides all the feedback)
	_apply_emoji_fallback()
	
	# Update config hash to prevent redundant rebuilds
	_last_applied_config = _get_config_hash()
	_rebuilding = false


## Restore original font settings (for cleanup)
func restore_original_font() -> void:
	if ProjectSettings.has_setting(BACKUP_FONT_SETTING):
		var original := ProjectSettings.get_setting(BACKUP_FONT_SETTING, "")
		ProjectSettings.set_setting(CUSTOM_FONT_SETTING, original)
		ProjectSettings.set_setting(BACKUP_FONT_SETTING, null)
		ProjectSettings.save()
		print("[OmnEmoji] Restored original font settings.")


## Get info about current font configuration (useful for debugging)
func get_font_config() -> Dictionary:
	var emoji_id := _get_emoji_provider_id()
	var text_id := _get_text_provider_id()
	var emoji_provider := OmnEmojiFontProviders.get_emoji_provider(emoji_id) if emoji_id else {}
	var text_provider := OmnEmojiFontProviders.get_text_provider(text_id) if text_id else {}
	
	return {
		"enabled": _is_enabled(),
		"auto_download": _is_auto_download_enabled(),
		"emoji_provider_id": emoji_id,
		"emoji_provider_name": emoji_provider.get("name", "Custom/System"),
		"emoji_font_path": _get_emoji_font_path(),
		"emoji_font_installed": OmnEmojiFontProviders.is_emoji_font_installed(emoji_id) if emoji_id else true,
		"text_provider_id": text_id,
		"text_provider_name": text_provider.get("name", "Custom/System"),
		"text_font_path": _get_text_font_path(),
		"text_font_installed": OmnEmojiFontProviders.is_text_font_installed(text_id) if text_id else true,
		"using_system_emoji": _is_using_system_emoji(),
	}


## Download a specific font provider (public API - async)
## Connect to _downloader.download_completed signal to get results
func download_font(provider_id: String, is_emoji := true) -> void:
	if not _downloader:
		push_error("[OmnEmoji] Downloader not initialized")
		return
	
	if is_emoji:
		_downloader.download_emoji_font(provider_id)
	else:
		_downloader.download_text_font(provider_id)


## Get available emoji providers (public API)
func get_available_emoji_providers() -> Array:
	var result := []
	for id in OmnEmojiFontProviders.get_emoji_provider_ids():
		var p: Dictionary = OmnEmojiFontProviders.get_emoji_provider(id)
		result.append({
			"id": id,
			"name": p.get("name", id),
			"description": p.get("description", ""),
			"size_mb": p.get("size_mb", 0.0),
			"license": p.get("license", ""),
			"installed": OmnEmojiFontProviders.is_emoji_font_installed(id),
		})
	return result

#endregion
