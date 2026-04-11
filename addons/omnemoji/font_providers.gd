@tool
class_name OmnEmojiFontProviders
extends RefCounted
## Font Provider Registry for OmnEmoji
##
## This class manages emoji font providers with support for:
## - Multiple font sources (Noto, OpenMoji, Twemoji, Fluent, etc.)
## - Automatic downloading of missing fonts (including ZIP extraction)
## - Multiple mirror URLs for reliability
## - External JSON configuration for easy customization
##
## Provider definitions are loaded from JSON files in the providers/ directory:
##   - emoji_providers.json: Emoji font providers
##   - text_providers.json: Text font providers
##
## To add a new provider, edit the appropriate JSON file.

const ADDON_PATH := "res://addons/omnemoji/"
const FONTS_DIR := ADDON_PATH + "third_party/"
const DOWNLOAD_CACHE := "user://omnemoji_downloads/"
const PROVIDERS_DIR := ADDON_PATH + "providers/"

## Cached provider data (loaded from JSON)
static var _emoji_providers: Dictionary = {}
static var _text_providers: Dictionary = {}
static var _providers_loaded := false


#region Provider Loading

## Ensure providers are loaded from JSON
static func _ensure_providers_loaded() -> void:
	if _providers_loaded:
		return
	reload_providers()


## Reload providers from JSON files
static func reload_providers() -> void:
	_emoji_providers = _load_json_providers("emoji_providers.json")
	_text_providers = _load_json_providers("text_providers.json")
	_providers_loaded = true
	
	if _emoji_providers.is_empty():
		push_warning("OmnEmoji: No emoji providers loaded. Check providers/emoji_providers.json")
	if _text_providers.is_empty():
		push_warning("OmnEmoji: No text providers loaded. Check providers/text_providers.json")


## Load providers from a JSON file
static func _load_json_providers(filename: String) -> Dictionary:
	var path := PROVIDERS_DIR + filename
	
	if not FileAccess.file_exists(path):
		push_error("OmnEmoji: Provider file not found: %s" % path)
		return {}
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("OmnEmoji: Failed to open provider file: %s" % path)
		return {}
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("OmnEmoji: Failed to parse JSON in %s: %s (line %d)" % [
			filename, json.get_error_message(), json.get_error_line()
		])
		return {}
	
	var data = json.data
	if not data is Dictionary:
		push_error("OmnEmoji: Invalid JSON structure in %s - expected object" % filename)
		return {}
	
	# Validate and convert mirrors to proper arrays
	var providers: Dictionary = data.get("providers", {})
	for id in providers:
		var p: Dictionary = providers[id]
		# Ensure mirrors is an array
		if p.has("mirrors") and p["mirrors"] is Array:
			var mirrors := PackedStringArray()
			for m in p["mirrors"]:
				mirrors.append(str(m))
			p["mirrors"] = mirrors
	
	return providers


## Get the raw provider dictionaries (for advanced use)
static func get_emoji_providers_dict() -> Dictionary:
	_ensure_providers_loaded()
	return _emoji_providers


static func get_text_providers_dict() -> Dictionary:
	_ensure_providers_loaded()
	return _text_providers

#endregion


#region Provider Queries

## Get list of all emoji provider IDs
static func get_emoji_provider_ids() -> PackedStringArray:
	_ensure_providers_loaded()
	return PackedStringArray(_emoji_providers.keys())


## Get list of all text provider IDs
static func get_text_provider_ids() -> PackedStringArray:
	_ensure_providers_loaded()
	return PackedStringArray(_text_providers.keys())


## Get emoji provider info by ID
static func get_emoji_provider(id: String) -> Dictionary:
	_ensure_providers_loaded()
	return _emoji_providers.get(id, {})


## Get text provider info by ID
static func get_text_provider(id: String) -> Dictionary:
	_ensure_providers_loaded()
	return _text_providers.get(id, {})


## Get display names for emoji providers (for UI dropdowns)
static func get_emoji_provider_names() -> PackedStringArray:
	_ensure_providers_loaded()
	var names := PackedStringArray()
	for id in _emoji_providers:
		var p: Dictionary = _emoji_providers[id]
		names.append(p.get("name", ""))
	return names


## Get display names for text providers (for UI dropdowns)
static func get_text_provider_names() -> PackedStringArray:
	_ensure_providers_loaded()
	var names := PackedStringArray()
	for id in _text_providers:
		var p: Dictionary = _text_providers[id]
		names.append(p.get("name", ""))
	return names


## Get display names with size info
static func get_emoji_provider_labels() -> PackedStringArray:
	_ensure_providers_loaded()
	var labels := PackedStringArray()
	for id in _emoji_providers:
		var p: Dictionary = _emoji_providers[id]
		var p_name: String = p.get("name", "")
		var p_size: float = p.get("size_mb", 0.0)
		var recommended: bool = p.get("recommended", false)
		var suffix := " ★" if recommended else ""
		labels.append("%s (~%.1f MB)%s" % [p_name, p_size, suffix])
	return labels


## Get display names with size info for text providers
static func get_text_provider_labels() -> PackedStringArray:
	_ensure_providers_loaded()
	var labels := PackedStringArray()
	for id in _text_providers:
		var p: Dictionary = _text_providers[id]
		var p_name: String = p.get("name", "")
		var p_size: float = p.get("size_mb", 0.0)
		labels.append("%s (~%.1f MB)" % [p_name, p_size])
	return labels


## Get provider ID from display name (emoji)
static func get_emoji_provider_id_by_name(display_name: String) -> String:
	_ensure_providers_loaded()
	for id in _emoji_providers:
		var p: Dictionary = _emoji_providers[id]
		if p.get("name", "") == display_name:
			return id
	return ""


## Get provider ID from display name (text)
static func get_text_provider_id_by_name(display_name: String) -> String:
	_ensure_providers_loaded()
	for id in _text_providers:
		var p: Dictionary = _text_providers[id]
		if p.get("name", "") == display_name:
			return id
	return ""


## Get provider ID from index (for enum-based settings)
static func get_emoji_provider_id_by_index(index: int) -> String:
	_ensure_providers_loaded()
	var keys := _emoji_providers.keys()
	if index >= 0 and index < keys.size():
		return keys[index]
	return "noto"  # Default fallback


## Get text provider ID from index
static func get_text_provider_id_by_index(index: int) -> String:
	_ensure_providers_loaded()
	var keys := _text_providers.keys()
	if index >= 0 and index < keys.size():
		return keys[index]
	return "noto_sans"  # Default fallback


## Get recommended emoji provider ID
static func get_recommended_emoji_provider() -> String:
	_ensure_providers_loaded()
	for id in _emoji_providers:
		var p: Dictionary = _emoji_providers[id]
		if p.get("recommended", false):
			return id
	# Fallback to first provider or noto
	if not _emoji_providers.is_empty():
		return _emoji_providers.keys()[0]
	return "noto"

#endregion


#region Path Helpers

## Get local path for an emoji provider's font file
static func get_emoji_font_path(provider_id: String) -> String:
	var provider := get_emoji_provider(provider_id)
	if provider.is_empty():
		return ""
	var subdir: String = provider.get("subdir", "")
	var filename: String = provider.get("filename", "")
	return FONTS_DIR + subdir + "/" + filename


## Get local path for a text provider's font file
static func get_text_font_path(provider_id: String) -> String:
	var provider := get_text_provider(provider_id)
	if provider.is_empty():
		return ""
	var subdir: String = provider.get("subdir", "")
	var filename: String = provider.get("filename", "")
	return FONTS_DIR + subdir + "/" + filename


## Minimum valid font file size in bytes (fonts smaller than this are likely corrupt/incomplete)
const MIN_FONT_SIZE_BYTES := 10000  # 10KB minimum


## Check if an emoji provider's font is installed and valid
static func is_emoji_font_installed(provider_id: String) -> bool:
	var path := get_emoji_font_path(provider_id)
	return _is_font_file_valid(path)


## Check if a text provider's font is installed and valid
static func is_text_font_installed(provider_id: String) -> bool:
	var path := get_text_font_path(provider_id)
	return _is_font_file_valid(path)


## Check if a font file exists and has valid size
static func _is_font_file_valid(path: String) -> bool:
	if path.is_empty():
		return false
	if not FileAccess.file_exists(path):
		return false
	# Check file has minimum size (not empty or corrupt)
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var size := file.get_length()
	file.close()
	return size >= MIN_FONT_SIZE_BYTES


## Get file size for a font path (returns 0 if not found)
static func get_font_file_size(path: String) -> int:
	if path.is_empty() or not FileAccess.file_exists(path):
		return 0
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return 0
	var size := file.get_length()
	file.close()
	return size

#endregion


#region Download Status

## Download result status enum (used by font_downloader.gd)
enum DownloadStatus {
	SUCCESS,
	FAILED_NO_MIRRORS,
	FAILED_NETWORK,
	FAILED_WRITE,
	FAILED_HASH_MISMATCH,
	IN_PROGRESS,
}

#endregion


#region Utility

## Get a summary of all installed fonts with file sizes
static func get_installed_fonts_summary() -> String:
	_ensure_providers_loaded()
	var lines := PackedStringArray()
	lines.append("=== Emoji Fonts ===")
	for id in _emoji_providers:
		var p: Dictionary = _emoji_providers[id]
		var path := get_emoji_font_path(id)
		var size := get_font_file_size(path)
		var installed := "✓" if is_emoji_font_installed(id) else "✗"
		var name: String = p.get("name", id)
		var recommended := " ★" if p.get("recommended", false) else ""
		if size > 0:
			lines.append("  [%s] %s%s (%.2f MB)" % [installed, name, recommended, size / (1024.0 * 1024.0)])
		else:
			lines.append("  [%s] %s%s (not installed)" % [installed, name, recommended])
	
	lines.append("\n=== Text Fonts ===")
	for id in _text_providers:
		var p: Dictionary = _text_providers[id]
		var path := get_text_font_path(id)
		var size := get_font_file_size(path)
		var installed := "✓" if is_text_font_installed(id) else "✗"
		var name: String = p.get("name", id)
		if size > 0:
			lines.append("  [%s] %s (%.2f MB)" % [installed, name, size / (1024.0 * 1024.0)])
		else:
			lines.append("  [%s] %s (not installed)" % [installed, name])
	
	return "\n".join(lines)


## Get provider info formatted for display
static func format_provider_info(provider_id: String, is_emoji := true) -> String:
	var provider: Dictionary = get_emoji_provider(provider_id) if is_emoji else get_text_provider(provider_id)
	if provider.is_empty():
		return "Unknown provider"
	
	var name: String = provider.get("name", "Unknown")
	var description: String = provider.get("description", "")
	var size_mb: float = provider.get("size_mb", 0.0)
	var license: String = provider.get("license", "Unknown")
	var format: String = provider.get("format", "TTF")
	
	return "%s\n%s\nSize: ~%.1f MB | License: %s | Format: %s" % [
		name,
		description,
		size_mb,
		license,
		format,
	]

#endregion
