extends Node


signal auth_success(session)
signal auth_error(error)


# Supabase configs
const SUPABASE_URL = "https://cxfwlpkfjyzvgoaeqgfs.supabase.co"
var SUPABASE_ANON_KEY = ""

# Local server configs
var tcp_server: TCPServer
var local_port = 54321
var redirect_uri = "http://localhost:54321"

# PKCE configs
var code_verifier: String
var code_challenge: String

var http_request: HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

var cef_texture : CefTexture

func sign_in_with_google():
	_generate_pkce_params()
	
	if not _start_local_server():
		emit_signal("auth_error", "Failed to start local server")
		return
	
	var auth_url = _build_auth_url()
	
	OS.shell_open(auth_url)
	print("Opened browser for authentication. Waiting for callback...")
	
	
func _generate_pkce_params():
	code_verifier = _generate_random_string(64)
	
	var bytes = code_verifier.to_utf8_buffer()
	var hash_context = HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(bytes)
	var hashed = hash_context.finish()
	
	code_challenge = Marshalls.raw_to_base64(hashed)
	code_challenge = code_challenge.replace("+", "-").replace("/", "_").rstrip("=")

func _generate_random_string(length: int) -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	var result = ""
	for i in range(length):
		result += chars[randi() % chars.length()]
	return result
	
func _start_local_server() -> bool:
	tcp_server = TCPServer.new()
	var err = tcp_server.listen(local_port, "127.0.0.1")
	if err != OK:
		print("Failed to start TCP server on port ", local_port, ": ", err)
		# Try alternative ports
		var alt_ports = [54322, 9999, 8080]
		for port in alt_ports:
			err = tcp_server.listen(port, "127.0.0.1")
			if err == OK:
				local_port = port
				redirect_uri = "http://localhost:" + str(port)
				print("Started server on alternative port: ", port)
				break
		
		if err != OK:
			return false
	
	set_process(true)  # Enable _process to check for connections
	return true
	

var provider = "google"

func _build_auth_url() -> String:
	var params = {
		"provider": provider,
		"redirect_to": redirect_uri,
		"code_challenge": code_challenge,
		"code_challenge_method": "S256",
		"flow_type": "pkce" # important
	}
	
	var query_string = ""
	for key in params:
		if query_string != "":
			query_string += "&"
		query_string += key + "=" + params[key].uri_encode()
	
	return SUPABASE_URL + "/auth/v1/authorize?" + query_string
	

func _process(_delta):
	if not tcp_server or not tcp_server.is_listening():
		return
	
	if tcp_server.is_connection_available():
		var connection = tcp_server.take_connection()
		if connection:
			_handle_callback(connection)

func _handle_callback(connection: StreamPeerTCP):
	var buffer = PackedByteArray()
	var timeout = 0.0
	
	while connection.get_status() == StreamPeerTCP.STATUS_CONNECTED and timeout < 2.0:
		var available = connection.get_available_bytes()
		if available > 0:
			buffer.append_array(connection.get_data(available)[1])
			var request = buffer.get_string_from_utf8()
			
			# Check if we have the full request
			if request.contains("\r\n\r\n"):
				_process_callback_request(request, connection)
				break
		else:
			await get_tree().create_timer(0.01).timeout
			timeout += 0.01

func _process_callback_request(request: String, connection: StreamPeerTCP):
	print("Received callback request")
	
	var lines = request.split("\n")
	var request_line = lines[0] if lines.size() > 0 else ""
	
	if request_line.begins_with("GET"):
		var url_part = request_line.split(" ")[1]
		var query_start = url_part.find("?")
		var query = url_part.substr(query_start + 1)
		var params = _parse_query_params(query)
		
		# Check for error
		if params.has("error"):
			_send_callback_response(connection, false, params.get("error_description", "Authentication failed"))
			emit_signal("auth_error", params.get("error_description", "Authentication failed"))
			_cleanup_server()
			return
		
		# Get authorization code
		var code = params.get("code", "")
		if code != "":
			_send_callback_response(connection, true)
			_exchange_code_for_session(code)
		else:
			_send_callback_response(connection, false, "No authorization code received")
			emit_signal("auth_error", "No authorization code received")
			_cleanup_server()

func _parse_query_params(query: String) -> Dictionary:
	var params = {}
	var pairs = query.split("&")
	for pair in pairs:
		var kv = pair.split("=")
		if kv.size() == 2:
			params[kv[0].uri_decode()] = kv[1].uri_decode()
	return params

func _send_callback_response(connection: StreamPeerTCP, success: bool, error_msg: String = ""):
	var html_body = ""
	
	if success:
		html_body = """
		<html>
		<head>
			<title>Authentication Successful</title>
			<style>
				body { 
					font-family: sans-serif;
					display: flex;
					justify-content: center;
					align-items: center;
					height: 100vh;
					margin: 0;
				}
			</style>
		</head>
		<body>
			<div>
				<h1>Authentication Successful</h1>
			</div>
		</body>
		</html>
		"""
	else:
		html_body = """
		<html>
		<head>
			<title>Authentication Failed</title>
			<style>
				body { 
					font-family: sans-serif;
					display: flex;
					justify-content: center;
					align-items: center;
					height: 100vh;
					margin: 0;
				}
			</style>
		</head>
		<body>
			<div>
				<h1>Authentication Failed</h1>
			</div>
		</body>
		</html>
		""" % error_msg
	
	var response = "HTTP/1.1 200 OK\r\n"
	response += "Content-Type: text/html; charset=utf-8\r\n"
	response += "Content-Length: %d\r\n" % html_body.to_utf8_buffer().size()
	response += "Connection: close\r\n"
	response += "\r\n"
	response += html_body
	
	connection.put_data(response.to_utf8_buffer())
	connection.disconnect_from_host()

func _exchange_code_for_session(code: String):
	print("Exchanging code for session...")
	
	var url = SUPABASE_URL + "/auth/v1/token?grant_type=pkce"
	
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY
	]
	
	var body = {
		"auth_code": code,
		"code_verifier": code_verifier
	}
	
	var json_body = JSON.stringify(body)
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	var response_text = body.get_string_from_utf8()
	
	# Check if this is a user info request
	if has_meta("temp_session"):
		var session = get_meta("temp_session")
		remove_meta("temp_session")
		if response_code == 200:
			var json = JSON.new()
			if json.parse(response_text) == OK:
				session["user"] = json.data
				emit_signal("auth_success", session)
				_store_session(session)
		else:
			emit_signal("auth_error", "Failed to get user info")
		
		_cleanup_server()
		return
	
	# Otherwise it's a token exchange response
	_cleanup_server()
	
	if response_code != 200:
		print("Auth error response: ", response_text)
		emit_signal("auth_error", "Authentication failed: " + response_text)
		return
	
	var json = JSON.new()
	var parse_result = json.parse(response_text)
	
	if parse_result != OK:
		emit_signal("auth_error", "Failed to parse authentication response")
		return
	
	var data = json.data
	
	# Extract session data
	var session = {
		"access_token": data.get("access_token", ""),
		"refresh_token": data.get("refresh_token", ""),
		"expires_in": data.get("expires_in", 0),
		"user": data.get("user", {})
	}
	
	print("Authentication successful! User: ", session.user.get("email", ""))
	emit_signal("auth_success", session)
	
	# Store tokens securely
	_store_session(session)

func _store_session(session: Dictionary):
	session["stored_at"] = Time.get_unix_time_from_system()
	
	# WARNING: This is a simple example. In production, use proper secure storage!
	var file = FileAccess.open("user://auth_session.dat", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(session))
		file.close()

func load_session() -> Dictionary:
	var file = FileAccess.open("user://auth_session.dat", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(content) == OK:
			var session = json.data
			
			# Check if session is expired
			if session.has("stored_at") and session.has("expires_in"):
				var age = Time.get_unix_time_from_system() - session.stored_at
				if age > session.expires_in - 300:  # 5 min buffer
					print("Stored session is expired")
					# Return session anyway so refresh_token can be attempted
					session["is_expired"] = true
			
			return session
	return {}

func is_session_valid() -> bool:
	var session = load_session()
	if not session.has("access_token") or session.access_token == "":
		return false
	
	if session.get("is_expired", false):
		return false
	
	return true
	
func refresh_token(refresh_token_str: String):
	var url = SUPABASE_URL + "/auth/v1/token?grant_type=refresh_token"
	
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY
	]
	
	var body = {
		"refresh_token": refresh_token_str
	}
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func sign_out():
	var session = load_session()
	if session.has("access_token"):
		var url = SUPABASE_URL + "/auth/v1/logout"
		var headers = [
			"Content-Type: application/json",
			"apikey: " + SUPABASE_ANON_KEY,
			"Authorization: Bearer " + session.access_token
		]
		
		http_request.request(url, headers, HTTPClient.METHOD_POST, "")
	
	# Clear stored session
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("auth_session.dat")



func _cleanup_server():
	if tcp_server:
		tcp_server.stop()
		tcp_server = null
	set_process(false)
