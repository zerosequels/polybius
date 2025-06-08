@tool
extends Node
class_name GodotAPI

func create_scene(params: Dictionary) -> Dictionary:
	var scene_name = params.get("name", "NewScene")
	var scene_path = params.get("path", "res://scenes/%s.tscn" % scene_name)
	var root_node_type = params.get("root_node_type", "Node")
	var create_directories = params.get("create_directories", false)
	
	# Get directory from path and validate/create if needed
	var directory_path = scene_path.get_base_dir()
	var dir = DirAccess.open("res://")
	var directory_created = ""
	
	# Check if directory exists
	if not dir.dir_exists(directory_path.replace("res://", "")):
		if create_directories:
			# Create directory hierarchy
			var make_dir_error = dir.make_dir_recursive(directory_path.replace("res://", ""))
			if make_dir_error != OK:
				return {
					"status": 500,
					"body": {
						"success": false,
						"error": "Failed to create directory '" + directory_path + "': " + str(make_dir_error)
					}
				}
			directory_created = directory_path
		else:
			# Directory doesn't exist and we're not creating it
			return {
				"status": 400,
				"body": {
					"success": false,
					"error": "Directory does not exist: " + directory_path + ". Use create_directories parameter to create it."
				}
			}
	
	var scene = PackedScene.new()
	var root_node = _create_node_by_type(root_node_type)
	
	if not root_node:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Invalid root node type: " + root_node_type
			}
		}
	
	root_node.name = scene_name
	scene.pack(root_node)
	
	var error = ResourceSaver.save(scene, scene_path)
	if error == OK:
		EditorInterface.open_scene_from_path(scene_path)
		var response_body = {
			"success": true,
			"scene_path": scene_path,
			"root_node_type": root_node_type,
			"message": "Scene created successfully"
		}
		if directory_created:
			response_body["directory_created"] = directory_created
		
		return {
			"status": 200,
			"body": response_body
		}
	else:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to save scene: " + str(error)
			}
		}

func open_scene(params: Dictionary) -> Dictionary:
	var scene_path = params.get("path", "")
	
	if scene_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Scene path is required"
			}
		}
	
	if not FileAccess.file_exists(scene_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Scene file not found: " + scene_path
			}
		}
	
	EditorInterface.open_scene_from_path(scene_path)
	return {
		"status": 200,
		"body": {
			"success": true,
			"scene_path": scene_path,
			"message": "Scene opened successfully"
		}
	}

func get_current_scene() -> Dictionary:
	var current_scene = EditorInterface.get_edited_scene_root()
	
	if not current_scene:
		return {
			"status": 200,
			"body": {
				"scene": null,
				"message": "No scene currently open"
			}
		}
	
	var scene_info = {
		"name": current_scene.name,
		"scene_file_path": current_scene.scene_file_path,
		"child_count": current_scene.get_child_count(),
		"type": current_scene.get_class()
	}
	
	return {
		"status": 200,
		"body": {
			"scene": scene_info,
			"message": "Current scene retrieved"
		}
	}

func add_node(params: Dictionary) -> Dictionary:
	var node_type = params.get("type", "Node")
	var node_name = params.get("name", "NewNode")
	var parent_path = params.get("parent_path", "")
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene currently open"
			}
		}
	
	var parent_node = current_scene
	if not parent_path.is_empty():
		parent_node = current_scene.get_node_or_null(parent_path)
		if not parent_node:
			return {
				"status": 404,
				"body": {
					"success": false,
					"error": "Parent node not found: " + parent_path
				}
			}
	
	var new_node = _create_node_by_type(node_type)
	if not new_node:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Invalid node type: " + node_type
			}
		}
	
	new_node.name = node_name
	parent_node.add_child(new_node)
	new_node.owner = current_scene
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": new_node.get_path(),
			"message": "Node added successfully"
		}
	}

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

func list_scenes() -> Dictionary:
	var scenes = []
	var dir = DirAccess.open("res://")
	_scan_directory_for_scenes(dir, "res://", scenes)
	
	return {
		"status": 200,
		"body": {
			"scenes": scenes,
			"count": scenes.size(),
			"message": "Scene list retrieved successfully"
		}
	}

func _scan_directory_for_scenes(dir: DirAccess, path: String, scenes: Array):
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
					_scan_directory_for_scenes(sub_dir, full_path, scenes)
		elif file_name.ends_with(".tscn"):
			var file_info = {
				"name": file_name.get_basename(),
				"path": full_path,
				"directory": path
			}
			scenes.append(file_info)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func duplicate_scene(params: Dictionary) -> Dictionary:
	var source_path = params.get("source_path", "")
	var target_path = params.get("target_path", "")
	var new_name = params.get("new_name", "")
	
	if source_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Source path is required"
			}
		}
	
	if not FileAccess.file_exists(source_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Source scene file not found: " + source_path
			}
		}
	
	# Generate target path if not provided
	if target_path.is_empty():
		var base_path = source_path.get_base_dir()
		var source_name = source_path.get_file().get_basename()
		var suffix = new_name if not new_name.is_empty() else "Copy"
		target_path = base_path + "/" + source_name + suffix + ".tscn"
	
	# Ensure target directory exists
	var target_dir = target_path.get_base_dir()
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(target_dir.replace("res://", "")):
		var make_dir_error = dir.make_dir_recursive(target_dir.replace("res://", ""))
		if make_dir_error != OK:
			return {
				"status": 500,
				"body": {
					"success": false,
					"error": "Failed to create target directory: " + str(make_dir_error)
				}
			}
	
	# Load the source scene and create a new one to avoid UUID conflicts
	var source_scene = load(source_path) as PackedScene
	if not source_scene:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to load source scene: " + source_path
			}
		}
	
	# Instantiate the scene to get its structure
	var scene_instance = source_scene.instantiate()
	if not scene_instance:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to instantiate source scene"
			}
		}
	
	# Create a new PackedScene and pack the instance (this generates new UUIDs)
	var new_scene = PackedScene.new()
	var pack_result = new_scene.pack(scene_instance)
	
	# Clean up the temporary instance
	scene_instance.queue_free()
	
	if pack_result != OK:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to pack new scene: " + str(pack_result)
			}
		}
	
	# Save the new scene
	var save_error = ResourceSaver.save(new_scene, target_path)
	if save_error != OK:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to save duplicated scene: " + str(save_error)
			}
		}
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"source_path": source_path,
			"target_path": target_path,
			"message": "Scene duplicated successfully"
		}
	}

func delete_scene(params: Dictionary) -> Dictionary:
	var scene_path = params.get("path", "")
	var confirm = params.get("confirm", false)
	
	if scene_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Scene path is required"
			}
		}
	
	if not confirm:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Deletion requires confirmation. Set confirm=true to proceed.",
				"scene_path": scene_path
			}
		}
	
	if not FileAccess.file_exists(scene_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Scene file not found: " + scene_path
			}
		}
	
	var dir = DirAccess.open("res://")
	var remove_error = dir.remove(scene_path)
	if remove_error != OK:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to delete scene file: " + str(remove_error)
			}
		}
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"scene_path": scene_path,
			"message": "Scene deleted successfully"
		}
	}

func delete_node(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var confirm = params.get("confirm", false)
	
	if node_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node path is required"
			}
		}
	
	if not confirm:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Deletion requires confirmation. Set confirm=true to proceed.",
				"node_path": node_path
			}
		}
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene currently open"
			}
		}
	
	var target_node = current_scene.get_node_or_null(node_path)
	if not target_node:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Node not found: " + node_path
			}
		}
	
	if target_node == current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Cannot delete the scene root node"
			}
		}
	
	target_node.queue_free()
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"message": "Node deleted successfully"
		}
	}

func move_node(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var new_parent_path = params.get("new_parent_path", "")
	var new_index = params.get("new_index", -1)
	
	if node_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node path is required"
			}
		}
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene currently open"
			}
		}
	
	var target_node = current_scene.get_node_or_null(node_path)
	if not target_node:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Node not found: " + node_path
			}
		}
	
	if target_node == current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Cannot move the scene root node"
			}
		}
	
	# Determine new parent
	var new_parent = current_scene
	if not new_parent_path.is_empty():
		new_parent = current_scene.get_node_or_null(new_parent_path)
		if not new_parent:
			return {
				"status": 404,
				"body": {
					"success": false,
					"error": "New parent node not found: " + new_parent_path
				}
			}
	
	# Remove from current parent
	var old_parent = target_node.get_parent()
	old_parent.remove_child(target_node)
	
	# Add to new parent
	new_parent.add_child(target_node)
	target_node.owner = current_scene
	
	# Set index if specified
	if new_index >= 0:
		new_parent.move_child(target_node, new_index)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"new_parent_path": new_parent.get_path(),
			"new_index": target_node.get_index(),
			"message": "Node moved successfully"
		}
	}

func get_node_properties(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	
	if node_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node path is required"
			}
		}
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene currently open"
			}
		}
	
	var target_node = current_scene.get_node_or_null(node_path)
	if not target_node:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Node not found: " + node_path
			}
		}
	
	var properties = {}
	var property_list = target_node.get_property_list()
	
	for property in property_list:
		if property.usage & PROPERTY_USAGE_STORAGE:
			var prop_name = property.name
			var prop_value = target_node.get(prop_name)
			properties[prop_name] = str(prop_value)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"node_type": target_node.get_class(),
			"properties": properties,
			"message": "Node properties retrieved successfully"
		}
	}

func set_node_properties(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var properties = params.get("properties", {})
	
	if node_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node path is required"
			}
		}
	
	if properties.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Properties dictionary is required"
			}
		}
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene currently open"
			}
		}
	
	var target_node = current_scene.get_node_or_null(node_path)
	if not target_node:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Node not found: " + node_path
			}
		}
	
	var set_properties = []
	var failed_properties = []
	
	for prop_name in properties:
		var prop_value = properties[prop_name]
		if target_node.has_method("set") and prop_name in target_node:
			target_node.set(prop_name, prop_value)
			set_properties.append(prop_name)
		else:
			failed_properties.append(prop_name)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"set_properties": set_properties,
			"failed_properties": failed_properties,
			"message": "Node properties updated"
		}
	}

func _create_node_by_type(type: String) -> Node:
	match type:
		"Node":
			return Node.new()
		"Node2D":
			return Node2D.new()
		"Node3D":
			return Node3D.new()
		"Control":
			return Control.new()
		"Label":
			return Label.new()
		"Button":
			return Button.new()
		"Sprite2D":
			return Sprite2D.new()
		"RigidBody2D":
			return RigidBody2D.new()
		"StaticBody2D":
			return StaticBody2D.new()
		"CharacterBody2D":
			return CharacterBody2D.new()
		"Camera2D":
			return Camera2D.new()
		"AudioStreamPlayer":
			return AudioStreamPlayer.new()
		"Timer":
			return Timer.new()
		_:
			return null

# Asset management functions
func import_asset(params: Dictionary) -> Dictionary:
	var source_path = params.get("source_path", "")
	var target_path = params.get("target_path", "")
	var asset_type = params.get("asset_type", "")
	
	if source_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Source path is required"
			}
		}
	
	if not FileAccess.file_exists(source_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Source file not found: " + source_path
			}
		}
	
	# Generate target path if not provided
	if target_path.is_empty():
		var file_name = source_path.get_file()
		var asset_dir = _get_asset_directory_for_type(asset_type)
		target_path = "res://" + asset_dir + "/" + file_name
	
	# Ensure target directory exists
	var target_dir = target_path.get_base_dir()
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(target_dir.replace("res://", "")):
		var make_dir_error = dir.make_dir_recursive(target_dir.replace("res://", ""))
		if make_dir_error != OK:
			return {
				"status": 500,
				"body": {
					"success": false,
					"error": "Failed to create target directory: " + str(make_dir_error)
				}
			}
	
	# Copy the file
	var copy_error = dir.copy(source_path, target_path)
	if copy_error != OK:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to copy file: " + str(copy_error)
			}
		}
	
	# Trigger reimport in editor
	EditorInterface.get_resource_filesystem().reimport_files([target_path])
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"source_path": source_path,
			"target_path": target_path,
			"asset_type": asset_type,
			"message": "Asset imported successfully"
		}
	}

func list_resources(params: Dictionary) -> Dictionary:
	var directory = params.get("directory", "res://")
	var file_types_param = params.get("file_types", "")
	var file_types = []
	if not file_types_param.is_empty():
		file_types = file_types_param.split(",")
	var recursive_param = params.get("recursive", "true")
	var recursive = recursive_param == "true" or recursive_param == true
	
	var resources = []
	var dir = DirAccess.open(directory)
	
	if not dir:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Directory not found: " + directory
			}
		}
	
	if recursive:
		_scan_directory_for_resources(dir, directory, resources, file_types)
	else:
		_scan_single_directory_for_resources(dir, directory, resources, file_types)
	
	return {
		"status": 200,
		"body": {
			"resources": resources,
			"count": resources.size(),
			"directory": directory,
			"message": "Resource list retrieved successfully"
		}
	}

func organize_assets(params: Dictionary) -> Dictionary:
	var source_path = params.get("source_path", "")
	var target_path = params.get("target_path", "")
	var update_references = params.get("update_references", true)
	
	if source_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Source path is required"
			}
		}
	
	if target_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Target path is required"
			}
		}
	
	if not FileAccess.file_exists(source_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Source file not found: " + source_path
			}
		}
	
	# Ensure target directory exists
	var target_dir = target_path.get_base_dir()
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(target_dir.replace("res://", "")):
		var make_dir_error = dir.make_dir_recursive(target_dir.replace("res://", ""))
		if make_dir_error != OK:
			return {
				"status": 500,
				"body": {
					"success": false,
					"error": "Failed to create target directory: " + str(make_dir_error)
				}
			}
	
	var references_updated = 0
	
	# Update references in scenes and scripts if requested
	if update_references:
		references_updated = _update_asset_references(source_path, target_path)
	
	# Move the file
	var move_error = dir.rename(source_path, target_path)
	if move_error != OK:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to move file: " + str(move_error)
			}
		}
	
	# Trigger reimport in editor
	EditorInterface.get_resource_filesystem().reimport_files([target_path])
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"source_path": source_path,
			"target_path": target_path,
			"references_updated": references_updated,
			"message": "Asset organized successfully"
		}
	}

# Project management functions
func get_project_settings(params: Dictionary) -> Dictionary:
	var setting_path = params.get("setting_path", "")
	
	if setting_path.is_empty():
		# Return all settings
		var all_settings = {}
		var setting_names = ProjectSettings.get_property_list()
		
		for setting in setting_names:
			if setting.usage & PROPERTY_USAGE_STORAGE:
				var name = setting.name
				var value = ProjectSettings.get_setting(name, "")
				all_settings[name] = str(value)
		
		return {
			"status": 200,
			"body": {
				"success": true,
				"settings": all_settings,
				"message": "All project settings retrieved"
			}
		}
	else:
		# Return specific setting
		if ProjectSettings.has_setting(setting_path):
			var value = ProjectSettings.get_setting(setting_path)
			return {
				"status": 200,
				"body": {
					"success": true,
					"setting_path": setting_path,
					"settings": value,
					"message": "Project setting retrieved"
				}
			}
		else:
			return {
				"status": 404,
				"body": {
					"success": false,
					"error": "Project setting not found: " + setting_path
				}
			}

func modify_project_settings(params: Dictionary) -> Dictionary:
	var setting_path = params.get("setting_path", "")
	var value = params.get("value")
	var create_if_missing = params.get("create_if_missing", false)
	
	if setting_path.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Setting path is required"
			}
		}
	
	if not ProjectSettings.has_setting(setting_path) and not create_if_missing:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Project setting not found: " + setting_path + ". Set create_if_missing=true to create it."
			}
		}
	
	ProjectSettings.set_setting(setting_path, value)
	var save_error = ProjectSettings.save()
	
	if save_error != OK:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to save project settings: " + str(save_error)
			}
		}
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"setting_path": setting_path,
			"value": value,
			"message": "Project setting updated successfully"
		}
	}

func export_project(params: Dictionary) -> Dictionary:
	var preset_name = params.get("preset_name", "")
	var output_path = params.get("output_path", "")
	var debug_mode = params.get("debug_mode", false)
	
	# Note: Export functionality requires EditorExportManager access which is not available in runtime
	# This is a framework implementation for future enhancement
	var export_presets = ["Windows Desktop", "Linux/X11", "macOS", "Android", "iOS", "Web"]
	
	if preset_name.is_empty():
		return {
			"status": 200,
			"body": {
				"success": true,
				"available_presets": export_presets,
				"message": "Available export presets listed. Specify preset_name to export. (Note: Export requires editor-only access)"
			}
		}
	
	# Validate preset name exists in common presets
	if not preset_name in export_presets:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Export preset not found: " + preset_name + ". Available presets: " + str(export_presets)
			}
		}
	
	# Use default output path if none specified
	if output_path.is_empty():
		output_path = "res://export/" + preset_name.replace(" ", "_").replace("/", "_") + "/game"
	
	# Note: Actual export functionality requires deeper integration with EditorExportManager
	# This would need to be implemented as an editor plugin rather than runtime script
	return {
		"status": 200,
		"body": {
			"success": true,
			"preset_name": preset_name,
			"output_path": output_path,
			"debug_mode": debug_mode,
			"message": "Export framework ready (Note: Full export implementation requires editor plugin integration)"
		}
	}

# Helper functions for asset management
func _get_asset_directory_for_type(asset_type: String) -> String:
	match asset_type:
		"image", "texture":
			return "textures"
		"audio":
			return "audio"
		"model":
			return "models"
		"font":
			return "fonts"
		_:
			return "assets"

func _scan_directory_for_resources(dir: DirAccess, path: String, resources: Array, file_types: Array):
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
					_scan_directory_for_resources(sub_dir, full_path, resources, file_types)
		else:
			_add_resource_if_matches(full_path, path, file_name, resources, file_types)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _scan_single_directory_for_resources(dir: DirAccess, path: String, resources: Array, file_types: Array):
	if not dir:
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
			
		var full_path = path + "/" + file_name if path != "res://" else "res://" + file_name
		
		if not dir.current_is_dir():
			_add_resource_if_matches(full_path, path, file_name, resources, file_types)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _add_resource_if_matches(full_path: String, directory: String, file_name: String, resources: Array, file_types: Array):
	# Check if file type matches filter
	if file_types.size() > 0:
		var matches_filter = false
		for file_type in file_types:
			if file_name.ends_with(file_type):
				matches_filter = true
				break
		if not matches_filter:
			return
	
	# Get file size
	var file = FileAccess.open(full_path, FileAccess.READ)
	var size = "unknown"
	if file:
		size = str(file.get_length()) + " bytes"
		file.close()
	
	# Determine asset type
	var asset_type = _get_asset_type_from_extension(file_name.get_extension())
	
	var resource_info = {
		"name": file_name.get_basename(),
		"path": full_path,
		"directory": directory,
		"size": size,
		"type": asset_type,
		"extension": file_name.get_extension()
	}
	resources.append(resource_info)

func _get_asset_type_from_extension(extension: String) -> String:
	match extension.to_lower():
		"png", "jpg", "jpeg", "bmp", "tga", "webp":
			return "image"
		"ogg", "wav", "mp3":
			return "audio"
		"gltf", "glb", "obj", "fbx", "dae":
			return "model"
		"ttf", "otf", "woff", "woff2":
			return "font"
		"tscn":
			return "scene"
		"gd":
			return "script"
		"tres", "res":
			return "resource"
		_:
			return "other"

func _update_asset_references(old_path: String, new_path: String) -> int:
	var references_updated = 0
	
	# This is a simplified implementation
	# In a full implementation, you would scan all .tscn and .gd files
	# and update any references to the old path
	
	# For now, we'll just return 0 as a placeholder
	# Real implementation would involve:
	# 1. Scanning all scene files for resource references
	# 2. Scanning all script files for load() calls
	# 3. Updating the references and saving the files
	
	return references_updated