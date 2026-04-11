@tool
class_name OmnEmojiFontDownloader
extends Node
## Async Font Downloader for OmnEmoji
##
## Uses HTTPRequest for cross-platform native downloads.
## Supports both direct TTF downloads and ZIP archives.
## Must be added to the scene tree to work.

signal download_completed(result: Dictionary)
signal download_progress(provider_id: String, bytes_downloaded: int, bytes_total: int)

const FONTS_DIR := "res://addons/omnemoji/third_party/"

var _http_request: HTTPRequest
var _current_provider: Dictionary
var _current_provider_id: String
var _current_target_path: String
var _current_target_dir: String
var _current_mirrors: Array
var _current_mirror_index: int
var _is_emoji: bool
var _is_zip_download: bool  # Whether current download is a ZIP file


## Ensure HTTPRequest node is initialized
func _ensure_http_request() -> void:
	if _http_request != null:
		return
	
	_http_request = HTTPRequest.new()
	_http_request.use_threads = true
	_http_request.timeout = 180.0  # 3 minute timeout for larger files
	_http_request.request_completed.connect(_on_request_completed)
	add_child(_http_request)


## Start downloading an emoji font
func download_emoji_font(provider_id: String) -> void:
	var provider := OmnEmojiFontProviders.get_emoji_provider(provider_id)
	if provider.is_empty():
		_emit_failed("Unknown provider: " + provider_id)
		return
	
	_is_emoji = true
	_start_download(provider_id, provider)


## Start downloading a text font
func download_text_font(provider_id: String) -> void:
	var provider := OmnEmojiFontProviders.get_text_provider(provider_id)
	if provider.is_empty():
		_emit_failed("Unknown provider: " + provider_id)
		return
	
	_is_emoji = false
	_start_download(provider_id, provider)


## Internal: Start the download process
func _start_download(provider_id: String, provider: Dictionary) -> void:
	# Ensure HTTPRequest is ready
	_ensure_http_request()
	
	_current_provider_id = provider_id
	_current_provider = provider
	_current_mirrors = provider.get("mirrors", [])
	_current_mirror_index = 0
	
	if _current_mirrors.is_empty():
		_emit_failed("No download mirrors available")
		return
	
	# Setup target path
	var subdir: String = provider.get("subdir", "")
	var filename: String = provider.get("filename", "")
	_current_target_dir = FONTS_DIR + subdir + "/"
	_current_target_path = _current_target_dir + filename
	
	# Check if this provider uses ZIP download
	_is_zip_download = provider.get("zip_download", false)
	
	# Ensure directory exists
	if not DirAccess.dir_exists_absolute(_current_target_dir):
		var err := DirAccess.make_dir_recursive_absolute(_current_target_dir)
		if err != OK:
			_emit_failed("Cannot create directory: " + _current_target_dir)
			return
	
	# Create .gdignore to exclude raw TTF files from exports (they're embedded in .tres)
	_ensure_gdignore(_current_target_dir)
	
	# Start with first mirror
	_try_next_mirror()


## Try the next mirror in the list
func _try_next_mirror() -> void:
	if _current_mirror_index >= _current_mirrors.size():
		_emit_failed("All mirrors failed")
		return
	
	var url: String = _current_mirrors[_current_mirror_index]
	print("[OmnEmoji] ⬇ Downloading from: ", url)
	
	# Use globalized path for download_file
	var global_path := ProjectSettings.globalize_path(_current_target_path)
	
	var err := _http_request.request(url)
	if err != OK:
		print("[OmnEmoji] Request error: ", error_string(err))
		_current_mirror_index += 1
		call_deferred("_try_next_mirror")
		return


## Handle HTTP request completion
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Check for errors
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg := _get_result_error_message(result)
		print("[OmnEmoji] Mirror failed: ", error_msg)
		_current_mirror_index += 1
		_try_next_mirror()
		return
	
	# Handle redirects (HTTPRequest should follow them, but just in case)
	if response_code >= 300 and response_code < 400:
		print("[OmnEmoji] Unexpected redirect: ", response_code)
		_current_mirror_index += 1
		_try_next_mirror()
		return
	
	# Check HTTP status
	if response_code != 200:
		print("[OmnEmoji] HTTP error: ", response_code)
		_current_mirror_index += 1
		_try_next_mirror()
		return
	
	# Check body size
	if body.size() == 0:
		print("[OmnEmoji] Empty response body")
		_current_mirror_index += 1
		_try_next_mirror()
		return
	
	# Handle ZIP or direct file
	if _is_zip_download:
		if not _extract_font_from_zip(body):
			_current_mirror_index += 1
			_try_next_mirror()
			return
	else:
		# Verify hash if provided (only for direct downloads)
		var expected_sha256: String = _current_provider.get("sha256", "")
		if expected_sha256 != "":
			var ctx := HashingContext.new()
			ctx.start(HashingContext.HASH_SHA256)
			ctx.update(body)
			var actual_hash := ctx.finish().hex_encode()
			if actual_hash != expected_sha256:
				print("[OmnEmoji] Hash mismatch!")
				_current_mirror_index += 1
				_try_next_mirror()
				return
		
		# Write file directly
		var file := FileAccess.open(_current_target_path, FileAccess.WRITE)
		if not file:
			_emit_failed("Cannot write to: " + _current_target_path)
			return
		
		file.store_buffer(body)
		file.close()
	
	# Create license file
	_create_license_file()
	
	# Verify the font file exists and has valid size
	if not FileAccess.file_exists(_current_target_path):
		_emit_failed("Font file not found after extraction: " + _current_target_path)
		return
	
	var file := FileAccess.open(_current_target_path, FileAccess.READ)
	if not file:
		_emit_failed("Cannot open font file for verification: " + _current_target_path)
		return
	
	var final_size := file.get_length()
	file.close()
	
	# Minimum font file size check (10KB minimum)
	const MIN_FONT_SIZE := 10000
	if final_size < MIN_FONT_SIZE:
		print("[OmnEmoji] ✗ Downloaded file too small (%d bytes), likely corrupt" % final_size)
		# Delete the corrupt file
		DirAccess.remove_absolute(_current_target_path)
		_current_mirror_index += 1
		_try_next_mirror()
		return
	
	# Success!
	var size_mb := final_size / (1024.0 * 1024.0)
	print("[OmnEmoji] ✓ Downloaded: %s (%.2f MB)" % [_current_target_path, size_mb])
	
	download_completed.emit({
		"status": OmnEmojiFontProviders.DownloadStatus.SUCCESS,
		"message": "OK",
		"path": _current_target_path,
		"provider_id": _current_provider_id,
		"is_emoji": _is_emoji,
	})


## Extract font file from ZIP archive
func _extract_font_from_zip(zip_data: PackedByteArray) -> bool:
	var zip_filename: String = _current_provider.get("zip_filename", "")
	var target_filename: String = _current_provider.get("filename", "")
	
	if zip_filename.is_empty():
		print("[OmnEmoji] ✗ No zip_filename specified in provider config")
		return false
	
	print("[OmnEmoji] 📦 ZIP download complete (%.2f MB)" % (zip_data.size() / (1024.0 * 1024.0)))
	print("[OmnEmoji] 📦 Looking for: %s" % zip_filename)
	
	# Save ZIP to temp file (ZIPReader needs a file path)
	var temp_zip_path := _current_target_dir + "_temp_download.zip"
	var temp_file := FileAccess.open(temp_zip_path, FileAccess.WRITE)
	if not temp_file:
		print("[OmnEmoji] Cannot create temp ZIP file")
		return false
	
	temp_file.store_buffer(zip_data)
	temp_file.close()
	
	# Open and extract from ZIP
	var zip := ZIPReader.new()
	var err := zip.open(temp_zip_path)
	if err != OK:
		print("[OmnEmoji] Cannot open ZIP: ", error_string(err))
		DirAccess.remove_absolute(temp_zip_path)
		return false
	
	# Find the font file in the ZIP
	var files := zip.get_files()
	var found_file := ""
	
	for f in files:
		# Match by exact name or ending with the filename
		if f == zip_filename or f.ends_with("/" + zip_filename) or f.ends_with(zip_filename):
			found_file = f
			break
	
	if found_file.is_empty():
		print("[OmnEmoji] ✗ Font file '%s' not found in ZIP" % zip_filename)
		print("[OmnEmoji]   Available font files in ZIP:")
		for f in files:
			if f.ends_with(".ttf") or f.ends_with(".otf"):
				print("[OmnEmoji]     - %s" % f)
		zip.close()
		DirAccess.remove_absolute(temp_zip_path)
		return false
	
	print("[OmnEmoji] 📦 Found: %s" % found_file)
	
	# Extract the font file
	var font_data := zip.read_file(found_file)
	zip.close()
	
	# Clean up temp ZIP
	DirAccess.remove_absolute(temp_zip_path)
	
	if font_data.is_empty():
		print("[OmnEmoji] ✗ Extracted font data is empty")
		return false
	
	# Check extracted size
	var extract_size_mb := font_data.size() / (1024.0 * 1024.0)
	print("[OmnEmoji] 📦 Extracted: %.2f MB" % extract_size_mb)
	
	# Write the extracted font
	var font_file := FileAccess.open(_current_target_path, FileAccess.WRITE)
	if not font_file:
		print("[OmnEmoji] ✗ Cannot write extracted font to: %s" % _current_target_path)
		return false
	
	font_file.store_buffer(font_data)
	font_file.close()
	
	# Verify write was successful
	if not FileAccess.file_exists(_current_target_path):
		print("[OmnEmoji] ✗ Font file not created after write")
		return false
	
	var verify_file := FileAccess.open(_current_target_path, FileAccess.READ)
	if not verify_file:
		print("[OmnEmoji] ✗ Cannot verify written file")
		return false
	
	var written_size := verify_file.get_length()
	verify_file.close()
	
	if written_size != font_data.size():
		print("[OmnEmoji] ✗ Write verification failed: expected %d bytes, got %d" % [font_data.size(), written_size])
		return false
	
	print("[OmnEmoji] ✓ Saved: %s (%.2f MB)" % [target_filename, extract_size_mb])
	return true


## Get human-readable error message for HTTPRequest result
func _get_result_error_message(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CANT_CONNECT:
			return "Cannot connect to host"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "Cannot resolve hostname"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "Connection error"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "TLS/SSL handshake failed"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "No response from server"
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return "Response too large"
		HTTPRequest.RESULT_BODY_DECOMPRESS_FAILED:
			return "Failed to decompress response"
		HTTPRequest.RESULT_REQUEST_FAILED:
			return "Request failed"
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
			return "Cannot open download file"
		HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			return "Cannot write to download file"
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			return "Too many redirects"
		HTTPRequest.RESULT_TIMEOUT:
			return "Request timeout"
		_:
			return "Unknown error: " + str(result)


## Emit a failure result
func _emit_failed(message: String) -> void:
	download_completed.emit({
		"status": OmnEmojiFontProviders.DownloadStatus.FAILED_NETWORK,
		"message": message,
		"path": "",
		"provider_id": _current_provider_id,
		"is_emoji": _is_emoji,
	})


## Create license file for downloaded font
func _create_license_file() -> void:
	var subdir: String = _current_provider.get("subdir", "")
	var dir := FONTS_DIR + subdir + "/"
	var license_path := dir + "LICENSE.txt"
	
	if FileAccess.file_exists(license_path):
		return
	
	var file := FileAccess.open(license_path, FileAccess.WRITE)
	if file:
		var font_name: String = _current_provider.get("name", "Unknown")
		var license_type: String = _current_provider.get("license", "Unknown")
		var license_url: String = _current_provider.get("license_url", "")
		file.store_string("Font: %s\n" % font_name)
		file.store_string("License: %s\n" % license_type)
		file.store_string("License URL: %s\n" % license_url)
		file.store_string("\nDownloaded by OmnEmoji addon for Godot.\n")
		file.store_string("See the license URL above for full license terms.\n")
		file.close()


## Ensure .gdignore exists in directory to exclude source TTF files from exports
func _ensure_gdignore(dir: String) -> void:
	var gdignore_path := dir + ".gdignore"
	if not FileAccess.file_exists(gdignore_path):
		var f := FileAccess.open(gdignore_path, FileAccess.WRITE)
		if f:
			f.close()
			print("[OmnEmoji] Created .gdignore in: %s" % dir)


## Check if a download is in progress
func is_downloading() -> bool:
	return _http_request != null and _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED
