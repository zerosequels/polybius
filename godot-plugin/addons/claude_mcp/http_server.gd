@tool
extends Node
class_name HTTPServer

var tcp_server: TCPServer
var port: int = 8080
var is_running: bool = false
var godot_api

func _ready():
	if not godot_api:
		var GodotAPIScript = preload("res://addons/claude_mcp/godot_api.gd")
		godot_api = GodotAPIScript.new()
		add_child(godot_api)

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
	var path = parts[1]
	
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
	
	return route_request(method, path, body_json)

func route_request(method: String, path: String, body: Dictionary) -> Dictionary:
	match [method, path]:
		["GET", "/health"]:
			return {"status": 200, "body": {"status": "ok", "plugin": "claude_mcp"}}
		
		["POST", "/scene/create"]:
			return godot_api.create_scene(body)
		
		["POST", "/scene/open"]:
			return godot_api.open_scene(body)
		
		["GET", "/scene/current"]:
			return godot_api.get_current_scene()
		
		["POST", "/node/add"]:
			return godot_api.add_node(body)
		
		["POST", "/script/create"]:
			return godot_api.create_script(body)
		
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