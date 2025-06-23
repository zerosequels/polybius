@tool
extends Node
class_name ScriptsAPI

func create_script(params: Dictionary) -> Dictionary:
	var script_path = params.get("path", "")
	var script_content = params.get("content", "extends Node\n\n# Called when the node enters the scene tree for the first time.\nfunc _ready():\n\tpass\n")
	var attach_to_node = params.get("attach_to_node", "")
	
	if script_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Script path is required"
			}
		}
	
	# Ensure directory exists
	var dir_path = script_path.get_base_dir()
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(dir_path.replace("res://", "")):
		var make_dir_error = dir.make_dir_recursive(dir_path.replace("res://", ""))
		if make_dir_error != OK:
			return {
				"status": 500,
				"body": {
					"success": false,
					"error": "Failed to create directory: " + str(make_dir_error)
				}
			}
	
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if not file:
		var error_code = FileAccess.get_open_error()
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to create script file. Error code: " + str(error_code) + ", Path: " + script_path
			}
		}
	
	file.store_string(script_content)
	file.close()
	
	if not attach_to_node.is_empty():
		var current_scene = EditorInterface.get_edited_scene_root()
		if current_scene:
			var target_node = current_scene.get_node_or_null(attach_to_node)
			if target_node:
				var script = load(script_path)
				target_node.set_script(script)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"script_path": script_path,
			"message": "Script created successfully"
		}
	}

func list_scripts() -> Dictionary:
	var scripts = []
	var dir = DirAccess.open("res://")
	_scan_directory_for_scripts(dir, "res://", scripts)
	
	return {
		"status": 200,
		"body": {
			"scripts": scripts,
			"count": scripts.size(),
			"message": "Script list retrieved successfully"
		}
	}

func _scan_directory_for_scripts(dir: DirAccess, path: String, scripts: Array):
	if not dir:
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
			
		var full_path = path + "/" + file_name if path != "res://" else "res://" + file_name
		
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				var sub_dir = DirAccess.open(full_path)
				if sub_dir:
					_scan_directory_for_scripts(sub_dir, full_path, scripts)
		elif file_name.ends_with(".gd"):
			var file_info = {
				"name": file_name.get_basename(),
				"path": full_path,
				"directory": path
			}
			scripts.append(file_info)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func read_script(params: Dictionary) -> Dictionary:
	var script_path = params.get("path", "")
	
	if script_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Script path is required"
			}
		}
	
	if not FileAccess.file_exists(script_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Script file not found: " + script_path
			}
		}
	
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to open script file: " + script_path
			}
		}
	
	var content = file.get_as_text()
	file.close()
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"script_path": script_path,
			"content": content,
			"message": "Script content retrieved successfully"
		}
	}

func modify_script(params: Dictionary) -> Dictionary:
	var script_path = params.get("path", "")
	var new_content = params.get("content", "")
	
	if script_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Script path is required"
			}
		}
	
	if new_content.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Script content is required"
			}
		}
	
	if not FileAccess.file_exists(script_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Script file not found: " + script_path
			}
		}
	
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if not file:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to open script file for writing: " + script_path
			}
		}
	
	file.store_string(new_content)
	file.close()
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"script_path": script_path,
			"message": "Script modified successfully"
		}
	}

func delete_script(params: Dictionary) -> Dictionary:
	var script_path = params.get("path", "")
	var confirm = params.get("confirm", false)
	
	if script_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Script path is required"
			}
		}
	
	if not confirm:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Deletion requires confirmation. Set confirm=true to proceed.",
				"script_path": script_path
			}
		}
	
	if not FileAccess.file_exists(script_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Script file not found: " + script_path
			}
		}
	
	var dir = DirAccess.open("res://")
	var remove_error = dir.remove(script_path)
	if remove_error != OK:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to delete script file: " + str(remove_error)
			}
		}
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"script_path": script_path,
			"message": "Script deleted successfully"
		}
	}
