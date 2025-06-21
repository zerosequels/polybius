@tool
extends Node
class_name HTTPServer

var tcp_server: TCPServer
var port: int = 8080
var is_running: bool = false
var godot_api
var error_log: Array = []
var max_log_entries: int = 100

func _ready():
	if not godot_api:
		var script_path = get_script().resource_path.get_base_dir()
		var GodotAPIScript = load(script_path + "/godot_api.gd")
		godot_api = GodotAPIScript.new()
		add_child(godot_api)
	
	# Set up error capture
	_setup_error_capture()

func start_server():
	tcp_server = TCPServer.new()
	var error = tcp_server.listen(port, "127.0.0.1")
	if error == OK:
		is_running = true
		print("HTTP Server listening on port ", port)
	else:
		print("Failed to start HTTP server: ", error)

func stop_server():
	if tcp_server:
		tcp_server.stop()
		is_running = false
		print("HTTP Server stopped")

func _process(_delta):
	if not is_running or not tcp_server:
		return
	
	if tcp_server.is_connection_available():
		var client = tcp_server.take_connection()
		handle_client(client)

func handle_client(client: StreamPeerTCP):
	var request = ""
	var bytes_to_read = 1024
	
	while client.get_available_bytes() > 0:
		var chunk = client.get_string(min(bytes_to_read, client.get_available_bytes()))
		request += chunk
		if request.ends_with("\r\n\r\n"):
			break
	
	var response = process_request(request)
	send_response(client, response)
	client.disconnect_from_host()

func process_request(request: String) -> Dictionary:
	var lines = request.split("\n")
	if lines.size() == 0:
		return {"status": 400, "body": "Bad Request"}
	
	var request_line = lines[0].strip_edges()
	var parts = request_line.split(" ")
	
	if parts.size() < 2:
		return {"status": 400, "body": "Bad Request"}
	
	var method = parts[0]
	var path_with_query = parts[1]
	
	# Separate path and query parameters
	var path = path_with_query
	var query_params = {}
	if "?" in path_with_query:
		var path_parts = path_with_query.split("?", false, 1)
		path = path_parts[0]
		if path_parts.size() > 1:
			var query_string = path_parts[1]
			var param_pairs = query_string.split("&")
			for pair in param_pairs:
				var kv = pair.split("=", false, 1)
				if kv.size() == 2:
					query_params[kv[0]] = kv[1].uri_decode()
	
	# Extract JSON body for POST requests
	var body_json = {}
	if method == "POST":
		var body_start = request.find("\r\n\r\n")
		if body_start != -1:
			var body = request.substr(body_start + 4)
			var json = JSON.new()
			var parse_result = json.parse(body)
			if parse_result == OK:
				body_json = json.data
	
	# Merge query params into body for GET requests
	if method == "GET" and query_params.size() > 0:
		body_json = query_params
	
	return route_request(method, path, body_json)

func route_request(method: String, path: String, body: Dictionary) -> Dictionary:
	match [method, path]:
		["GET", "/health"]:
			return {"status": 200, "body": {"status": "ok", "plugin": "claude_mcp"}}
		
		["GET", "/debug/filesystem"]:
			var dir = DirAccess.open("res://")
			return {
				"status": 200, 
				"body": {
					"current_dir": dir.get_current_dir(),
					"scripts_dir_exists": dir.dir_exists("scripts"),
					"can_write": true
				}
			}
		
		["POST", "/scene/create"]:
			return godot_api.create_scene(body)
		
		["POST", "/scene/open"]:
			return godot_api.open_scene(body)
		
		["GET", "/scene/current"]:
			return godot_api.get_current_scene()
		
		["GET", "/scene/list"]:
			return godot_api.list_scenes()
		
		["POST", "/scene/duplicate"]:
			return godot_api.duplicate_scene(body)
		
		["POST", "/scene/delete"]:
			return godot_api.delete_scene(body)
		
		["POST", "/node/add"]:
			return godot_api.add_node(body)
		
		["POST", "/node/delete"]:
			return godot_api.delete_node(body)
		
		["POST", "/node/move"]:
			return godot_api.move_node(body)
		
		["POST", "/node/properties/get"]:
			return godot_api.get_node_properties(body)
		
		["POST", "/node/properties/set"]:
			return godot_api.set_node_properties(body)
		
		["POST", "/script/create"]:
			return godot_api.create_script(body)
		
		["GET", "/script/list"]:
			return godot_api.list_scripts()
		
		["POST", "/script/read"]:
			return godot_api.read_script(body)
		
		["POST", "/script/modify"]:
			return godot_api.modify_script(body)
		
		["POST", "/script/delete"]:
			return godot_api.delete_script(body)
		
		# Asset management endpoints
		["POST", "/asset/import"]:
			return godot_api.import_asset(body)
		
		["GET", "/asset/list"]:
			return godot_api.list_resources(body)
		
		["POST", "/asset/organize"]:
			return godot_api.organize_assets(body)
		
		# Project management endpoints
		["GET", "/project/settings"]:
			return godot_api.get_project_settings(body)
		
		["POST", "/project/settings"]:
			return godot_api.modify_project_settings(body)
		
		["POST", "/project/export"]:
			return godot_api.export_project(body)
		
		# UI Control endpoints
		["POST", "/control/anchors"]:
			return godot_api.set_control_anchors(body)
		
		["POST", "/control/center"]:
			return godot_api.center_control(body)
		
		["POST", "/control/position"]:
			return godot_api.position_control(body)
		
		["POST", "/control/fit"]:
			return godot_api.fit_control_to_parent(body)
		
		["POST", "/control/margins"]:
			return godot_api.set_anchor_margins(body)
		
		["POST", "/control/size_flags"]:
			return godot_api.configure_size_flags(body)
		
		["POST", "/control/rect"]:
			return godot_api.setup_control_rect(body)
		
		# Smart UI Creation Helper endpoints
		["POST", "/ui/create_centered"]:
			return godot_api.create_centered_ui(body)
		
		["POST", "/ui/create_fullscreen"]:
			return godot_api.create_fullscreen_ui(body)
		
		["POST", "/ui/container_with_children"]:
			return godot_api.setup_ui_container_with_children(body)
		
		["POST", "/ui/apply_pattern"]:
			return godot_api.apply_common_ui_patterns(body)
		
		# UI Layout Management endpoints
		["POST", "/layout/create"]:
			return godot_api.create_ui_layout(body)
		
		["POST", "/layout/anchor_preset"]:
			return godot_api.set_anchor_preset(body)
		
		["POST", "/layout/align"]:
			return godot_api.align_controls(body)
		
		["POST", "/layout/distribute"]:
			return godot_api.distribute_controls(body)
		
		# Theme management endpoints
		["POST", "/theme/create"]:
			return godot_api.create_theme(body)
		
		["POST", "/theme/apply"]:
			return godot_api.apply_theme(body)
		
		["POST", "/theme/modify"]:
			return godot_api.modify_theme_properties(body)
		
		["POST", "/theme/import"]:
			return godot_api.import_theme(body)
		
		["POST", "/theme/export"]:
			return godot_api.export_theme(body)
		
		["GET", "/theme/list"]:
			return godot_api.list_themes(body)
		
		["POST", "/theme/properties/get"]:
			return godot_api.get_theme_properties(body)
		
		# Animation & Interaction endpoints
		["POST", "/animation/create"]:
			return godot_api.create_ui_animation(body)
		
		["POST", "/animation/signals"]:
			return godot_api.configure_ui_signals(body)
		
		["POST", "/animation/focus"]:
			return godot_api.setup_focus_navigation(body)
		
		["POST", "/animation/control"]:
			return godot_api.start_ui_animation(body)
		
		["POST", "/animation/transition"]:
			return godot_api.create_ui_transition(body)
		
		# Node documentation and discovery endpoints
		["POST", "/node/class_info"]:
			return godot_api.get_node_class_info(body)
		
		["GET", "/node/list_classes"]:
			return godot_api.list_node_classes(body)
		
		["GET", "/errors"]:
			return get_error_log()
		
		["POST", "/errors/clear"]:
			return clear_error_log()
		
		_:
			return {"status": 404, "body": "Not Found"}

func send_response(client: StreamPeerTCP, response: Dictionary):
	var status_code = response.get("status", 200)
	var body = response.get("body", {})
	
	var json_body = JSON.stringify(body)
	var headers = "HTTP/1.1 %d OK\r\n" % status_code
	headers += "Content-Type: application/json\r\n"
	headers += "Content-Length: %d\r\n" % json_body.length()
	headers += "Access-Control-Allow-Origin: *\r\n"
	headers += "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
	headers += "Access-Control-Allow-Headers: Content-Type\r\n"
	headers += "\r\n"
	
	client.put_data((headers + json_body).to_utf8_buffer())

func _setup_error_capture():
	# Connect to Godot's internal error signals if available
	# Since we can't directly capture all Godot errors, we'll use a print override approach
	pass

func log_error(error_type: String, message: String, source: String = ""):
	var timestamp = Time.get_datetime_string_from_system()
	var error_entry = {
		"timestamp": timestamp,
		"type": error_type,
		"message": message,
		"source": source
	}
	
	error_log.append(error_entry)
	
	# Keep log size manageable
	if error_log.size() > max_log_entries:
		error_log.pop_front()
	
	print("Claude MCP Error Logged: [%s] %s: %s" % [timestamp, error_type, message])

func get_error_log() -> Dictionary:
	return {
		"status": 200,
		"body": {
			"errors": error_log,
			"count": error_log.size(),
			"message": "Error log retrieved successfully"
		}
	}

func clear_error_log() -> Dictionary:
	var cleared_count = error_log.size()
	error_log.clear()
	return {
		"status": 200,
		"body": {
			"success": true,
			"cleared_count": cleared_count,
			"message": "Error log cleared successfully"
		}
	}

# Wrapper function for API calls to catch and log errors
func safe_api_call(api_function: Callable, params: Dictionary) -> Dictionary:
	# Note: GDScript doesn't have try/catch - errors handled at call site
	var error_msg = "API call wrapper: " + str(api_function)
	log_error("API_CALL", error_msg, "http_server")
	return api_function.call(params)