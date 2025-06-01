@tool
extends EditorPlugin

var http_server

func _enter_tree():
	print("Claude MCP Plugin: Starting...")
	var script_path = get_script().resource_path.get_base_dir()
	var HTTPServerScript = load(script_path + "/http_server.gd")
	http_server = HTTPServerScript.new()
	add_child(http_server)
	http_server.start_server()
	print("Claude MCP Plugin: HTTP server started on port 8080")

func _exit_tree():
	print("Claude MCP Plugin: Stopping...")
	if http_server:
		http_server.stop_server()
		http_server.queue_free()
	print("Claude MCP Plugin: Stopped")

func get_plugin_name():
	return "Claude MCP Server"