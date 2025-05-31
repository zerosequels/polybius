@tool
extends EditorPlugin

var http_server: HTTPServer

func _enter_tree():
	print("Claude MCP Plugin: Starting...")
	http_server = HTTPServer.new()
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