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
		"Panel":
			return Panel.new()
		"PanelContainer":
			return PanelContainer.new()
		"VBoxContainer":
			return VBoxContainer.new()
		"HBoxContainer":
			return HBoxContainer.new()
		"GridContainer":
			return GridContainer.new()
		"MarginContainer":
			return MarginContainer.new()
		"TabContainer":
			return TabContainer.new()
		"HSplitContainer":
			return HSplitContainer.new()
		"VSplitContainer":
			return VSplitContainer.new()
		"ScrollContainer":
			return ScrollContainer.new()
		"ColorRect":
			return ColorRect.new()
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

# UI Control functions
func set_control_anchors(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var anchor_left = params.get("anchor_left", 0.0)
	var anchor_top = params.get("anchor_top", 0.0)
	var anchor_right = params.get("anchor_right", 0.0)
	var anchor_bottom = params.get("anchor_bottom", 0.0)
	
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
	
	if not target_node is Control:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node is not a Control node: " + node_path
			}
		}
	
	var control_node = target_node as Control
	control_node.anchor_left = anchor_left
	control_node.anchor_top = anchor_top
	control_node.anchor_right = anchor_right
	control_node.anchor_bottom = anchor_bottom
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"anchor_left": anchor_left,
			"anchor_top": anchor_top,
			"anchor_right": anchor_right,
			"anchor_bottom": anchor_bottom,
			"message": "Control anchors set successfully"
		}
	}

func center_control(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var horizontal = params.get("horizontal", true)
	var vertical = params.get("vertical", true)
	
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
	
	if not target_node is Control:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node is not a Control node: " + node_path
			}
		}
	
	var control_node = target_node as Control
	
	if horizontal and vertical:
		# Center both horizontally and vertically
		control_node.anchor_left = 0.5
		control_node.anchor_right = 0.5
		control_node.anchor_top = 0.5
		control_node.anchor_bottom = 0.5
		control_node.offset_left = -control_node.size.x / 2
		control_node.offset_right = control_node.size.x / 2
		control_node.offset_top = -control_node.size.y / 2
		control_node.offset_bottom = control_node.size.y / 2
	elif horizontal:
		# Center horizontally only
		control_node.anchor_left = 0.5
		control_node.anchor_right = 0.5
		control_node.offset_left = -control_node.size.x / 2
		control_node.offset_right = control_node.size.x / 2
	elif vertical:
		# Center vertically only
		control_node.anchor_top = 0.5
		control_node.anchor_bottom = 0.5
		control_node.offset_top = -control_node.size.y / 2
		control_node.offset_bottom = control_node.size.y / 2
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"horizontal": horizontal,
			"vertical": vertical,
			"message": "Control centered successfully"
		}
	}

func position_control(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var x = params.get("x", 0.0)
	var y = params.get("y", 0.0)
	var anchor_preset = params.get("anchor_preset", "")
	
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
	
	if not target_node is Control:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node is not a Control node: " + node_path
			}
		}
	
	var control_node = target_node as Control
	
	# Apply anchor preset if specified
	if not anchor_preset.is_empty():
		_apply_anchor_preset(control_node, anchor_preset)
	
	# Set position based on current anchors
	control_node.position = Vector2(x, y)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"x": x,
			"y": y,
			"anchor_preset": anchor_preset,
			"message": "Control positioned successfully"
		}
	}

func _apply_anchor_preset(control: Control, preset: String):
	match preset:
		"top_left":
			control.anchor_left = 0.0
			control.anchor_top = 0.0
			control.anchor_right = 0.0
			control.anchor_bottom = 0.0
		"top_right":
			control.anchor_left = 1.0
			control.anchor_top = 0.0
			control.anchor_right = 1.0
			control.anchor_bottom = 0.0
		"bottom_left":
			control.anchor_left = 0.0
			control.anchor_top = 1.0
			control.anchor_right = 0.0
			control.anchor_bottom = 1.0
		"bottom_right":
			control.anchor_left = 1.0
			control.anchor_top = 1.0
			control.anchor_right = 1.0
			control.anchor_bottom = 1.0
		"center_left":
			control.anchor_left = 0.0
			control.anchor_top = 0.5
			control.anchor_right = 0.0
			control.anchor_bottom = 0.5
		"center_top":
			control.anchor_left = 0.5
			control.anchor_top = 0.0
			control.anchor_right = 0.5
			control.anchor_bottom = 0.0
		"center_right":
			control.anchor_left = 1.0
			control.anchor_top = 0.5
			control.anchor_right = 1.0
			control.anchor_bottom = 0.5
		"center_bottom":
			control.anchor_left = 0.5
			control.anchor_top = 1.0
			control.anchor_right = 0.5
			control.anchor_bottom = 1.0
		"center":
			control.anchor_left = 0.5
			control.anchor_top = 0.5
			control.anchor_right = 0.5
			control.anchor_bottom = 0.5
		"full_rect":
			control.anchor_left = 0.0
			control.anchor_top = 0.0
			control.anchor_right = 1.0
			control.anchor_bottom = 1.0

func fit_control_to_parent(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var margin = params.get("margin", 0.0)
	
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
	
	if not target_node is Control:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node is not a Control node: " + node_path
			}
		}
	
	var control_node = target_node as Control
	
	# Set anchors to fill parent
	control_node.anchor_left = 0.0
	control_node.anchor_top = 0.0
	control_node.anchor_right = 1.0
	control_node.anchor_bottom = 1.0
	
	# Apply margins
	control_node.offset_left = margin
	control_node.offset_top = margin
	control_node.offset_right = -margin
	control_node.offset_bottom = -margin
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"margin": margin,
			"message": "Control fitted to parent successfully"
		}
	}

func set_anchor_margins(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var margin_left = params.get("margin_left", 0.0)
	var margin_top = params.get("margin_top", 0.0)
	var margin_right = params.get("margin_right", 0.0)
	var margin_bottom = params.get("margin_bottom", 0.0)
	
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
	
	if not target_node is Control:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node is not a Control node: " + node_path
			}
		}
	
	var control_node = target_node as Control
	control_node.offset_left = margin_left
	control_node.offset_top = margin_top
	control_node.offset_right = margin_right
	control_node.offset_bottom = margin_bottom
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"margin_left": margin_left,
			"margin_top": margin_top,
			"margin_right": margin_right,
			"margin_bottom": margin_bottom,
			"message": "Anchor margins set successfully"
		}
	}

func configure_size_flags(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var horizontal_flags = params.get("horizontal_flags", [])
	var vertical_flags = params.get("vertical_flags", [])
	
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
	
	if not target_node is Control:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node is not a Control node: " + node_path
			}
		}
	
	var control_node = target_node as Control
	
	# Configure horizontal size flags
	if horizontal_flags.size() > 0:
		var h_flags = 0
		for flag in horizontal_flags:
			match flag:
				"fill":
					h_flags |= Control.SIZE_FILL
				"expand":
					h_flags |= Control.SIZE_EXPAND
				"shrink_center":
					h_flags |= Control.SIZE_SHRINK_CENTER
				"shrink_end":
					h_flags |= Control.SIZE_SHRINK_END
		control_node.size_flags_horizontal = h_flags
	
	# Configure vertical size flags
	if vertical_flags.size() > 0:
		var v_flags = 0
		for flag in vertical_flags:
			match flag:
				"fill":
					v_flags |= Control.SIZE_FILL
				"expand":
					v_flags |= Control.SIZE_EXPAND
				"shrink_center":
					v_flags |= Control.SIZE_SHRINK_CENTER
				"shrink_end":
					v_flags |= Control.SIZE_SHRINK_END
		control_node.size_flags_vertical = v_flags
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"horizontal_flags": horizontal_flags,
			"vertical_flags": vertical_flags,
			"message": "Size flags configured successfully"
		}
	}

func setup_control_rect(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var x = params.get("x", 0.0)
	var y = params.get("y", 0.0)
	var width = params.get("width", 100.0)
	var height = params.get("height", 100.0)
	var anchor_preset = params.get("anchor_preset", "")
	
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
	
	if not target_node is Control:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node is not a Control node: " + node_path
			}
		}
	
	var control_node = target_node as Control
	
	# Apply anchor preset if specified
	if not anchor_preset.is_empty():
		_apply_anchor_preset(control_node, anchor_preset)
	
	# Set position and size
	control_node.position = Vector2(x, y)
	control_node.size = Vector2(width, height)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"x": x,
			"y": y,
			"width": width,
			"height": height,
			"anchor_preset": anchor_preset,
			"message": "Control rect setup successfully"
		}
	}

# Smart UI Creation Helper functions
func create_centered_ui(params: Dictionary) -> Dictionary:
	var node_type = params.get("node_type", "Control")
	var name = params.get("name", "CenteredUI")
	var parent_path = params.get("parent_path", "")
	var width = params.get("width", 100.0)
	var height = params.get("height", 100.0)
	var text = params.get("text", "")
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene currently open"
			}
		}
	
	# Get parent node
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
	
	# Create the UI node
	var new_node = _create_node_by_type(node_type)
	if not new_node:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Invalid node type: " + node_type
			}
		}
	
	new_node.name = name
	parent_node.add_child(new_node)
	new_node.owner = current_scene
	
	# Set text if it's a text node
	if text and new_node.has_method("set_text"):
		new_node.set_text(text)
	
	# Make it a Control node and center it
	if new_node is Control:
		var control_node = new_node as Control
		control_node.size = Vector2(width, height)
		
		# Center anchors and position
		control_node.anchor_left = 0.5
		control_node.anchor_right = 0.5
		control_node.anchor_top = 0.5
		control_node.anchor_bottom = 0.5
		control_node.offset_left = -width / 2
		control_node.offset_right = width / 2
		control_node.offset_top = -height / 2
		control_node.offset_bottom = height / 2
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": new_node.get_path(),
			"node_type": node_type,
			"width": width,
			"height": height,
			"message": "Centered UI element created successfully"
		}
	}

func create_fullscreen_ui(params: Dictionary) -> Dictionary:
	var node_type = params.get("node_type", "Control")
	var name = params.get("name", "FullscreenUI")
	var parent_path = params.get("parent_path", "")
	var margin = params.get("margin", 0.0)
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene currently open"
			}
		}
	
	# Get parent node
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
	
	# Create the UI node
	var new_node = _create_node_by_type(node_type)
	if not new_node:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Invalid node type: " + node_type
			}
		}
	
	new_node.name = name
	parent_node.add_child(new_node)
	new_node.owner = current_scene
	
	# Make it a Control node and fit to parent
	if new_node is Control:
		var control_node = new_node as Control
		
		# Fill parent anchors and apply margins
		control_node.anchor_left = 0.0
		control_node.anchor_top = 0.0
		control_node.anchor_right = 1.0
		control_node.anchor_bottom = 1.0
		control_node.offset_left = margin
		control_node.offset_top = margin
		control_node.offset_right = -margin
		control_node.offset_bottom = -margin
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": new_node.get_path(),
			"node_type": node_type,
			"margin": margin,
			"message": "Fullscreen UI element created successfully"
		}
	}

func setup_ui_container_with_children(params: Dictionary) -> Dictionary:
	var container_type = params.get("container_type", "VBoxContainer")
	var container_name = params.get("container_name", "Container")
	var parent_path = params.get("parent_path", "")
	var positioning = params.get("positioning", "centered")
	var children = params.get("children", [])
	var spacing = params.get("spacing")
	var x = params.get("x")
	var y = params.get("y")
	var width = params.get("width")
	var height = params.get("height")
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene currently open"
			}
		}
	
	# Get parent node
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
	
	# Create the container
	var container = _create_node_by_type(container_type)
	if not container:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Invalid container type: " + container_type
			}
		}
	
	container.name = container_name
	parent_node.add_child(container)
	container.owner = current_scene
	
	# Set spacing for applicable containers
	if spacing != null and container.has_method("add_theme_constant_override"):
		if container_type in ["VBoxContainer", "HBoxContainer"]:
			container.add_theme_constant_override("separation", int(spacing))
	
	# Position the container based on positioning type
	if container is Control:
		var control_container = container as Control
		
		match positioning:
			"centered":
				control_container.anchor_left = 0.5
				control_container.anchor_right = 0.5
				control_container.anchor_top = 0.5
				control_container.anchor_bottom = 0.5
				if width != null and height != null:
					control_container.size = Vector2(width, height)
					control_container.offset_left = -width / 2
					control_container.offset_right = width / 2
					control_container.offset_top = -height / 2
					control_container.offset_bottom = height / 2
			
			"fullscreen":
				control_container.anchor_left = 0.0
				control_container.anchor_top = 0.0
				control_container.anchor_right = 1.0
				control_container.anchor_bottom = 1.0
				control_container.offset_left = 0
				control_container.offset_top = 0
				control_container.offset_right = 0
				control_container.offset_bottom = 0
			
			"top_left":
				control_container.anchor_left = 0.0
				control_container.anchor_top = 0.0
				control_container.anchor_right = 0.0
				control_container.anchor_bottom = 0.0
				if width != null and height != null:
					control_container.size = Vector2(width, height)
			
			"custom":
				if x != null and y != null:
					control_container.position = Vector2(x, y)
				if width != null and height != null:
					control_container.size = Vector2(width, height)
	
	# Create child elements
	var created_children = []
	for child_data in children:
		var child_type = child_data.get("type", "Label")
		var child_name = child_data.get("name", "Child")
		var child_text = child_data.get("text", "")
		var child_width = child_data.get("width")
		var child_height = child_data.get("height")
		
		var child_node = _create_node_by_type(child_type)
		if child_node:
			child_node.name = child_name
			container.add_child(child_node)
			child_node.owner = current_scene
			
			# Set text if applicable
			if child_text and child_node.has_method("set_text"):
				child_node.set_text(child_text)
			
			# Set custom size if specified
			if child_width != null and child_height != null and child_node is Control:
				var child_control = child_node as Control
				child_control.custom_minimum_size = Vector2(child_width, child_height)
			
			created_children.append(child_name)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"container_path": container.get_path(),
			"created_children": created_children,
			"positioning": positioning,
			"message": "UI container with children created successfully"
		}
	}

func apply_common_ui_patterns(params: Dictionary) -> Dictionary:
	var pattern = params.get("pattern", "")
	var parent_path = params.get("parent_path", "")
	var name_prefix = params.get("name_prefix", pattern)
	var customization = params.get("customization", {})
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene currently open"
			}
		}
	
	# Get parent node
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
	
	var created_nodes = []
	
	match pattern:
		"main_menu":
			var title = customization.get("title", "Game Title")
			var buttons = customization.get("buttons", ["Start Game", "Settings", "Quit"])
			
			# Create main container
			var menu_container = VBoxContainer.new()
			menu_container.name = name_prefix + "_Container"
			parent_node.add_child(menu_container)
			menu_container.owner = current_scene
			
			# Center the menu
			menu_container.anchor_left = 0.5
			menu_container.anchor_right = 0.5
			menu_container.anchor_top = 0.5
			menu_container.anchor_bottom = 0.5
			menu_container.offset_left = -150
			menu_container.offset_right = 150
			menu_container.offset_top = -100
			menu_container.offset_bottom = 100
			menu_container.add_theme_constant_override("separation", 20)
			
			# Create title label
			var title_label = Label.new()
			title_label.name = name_prefix + "_Title"
			title_label.text = title
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			menu_container.add_child(title_label)
			title_label.owner = current_scene
			created_nodes.append(title_label.name)
			
			# Create buttons
			for button_text in buttons:
				var button = Button.new()
				button.name = name_prefix + "_" + button_text.replace(" ", "")
				button.text = button_text
				menu_container.add_child(button)
				button.owner = current_scene
				created_nodes.append(button.name)
			
			created_nodes.append(menu_container.name)
		
		"hud":
			# Create HUD overlay
			var hud_container = Control.new()
			hud_container.name = name_prefix + "_HUD"
			parent_node.add_child(hud_container)
			hud_container.owner = current_scene
			
			# Fill screen
			hud_container.anchor_left = 0.0
			hud_container.anchor_top = 0.0
			hud_container.anchor_right = 1.0
			hud_container.anchor_bottom = 1.0
			
			# Health bar (top left)
			var health_container = HBoxContainer.new()
			health_container.name = name_prefix + "_HealthContainer"
			health_container.position = Vector2(20, 20)
			hud_container.add_child(health_container)
			health_container.owner = current_scene
			
			var health_label = Label.new()
			health_label.name = name_prefix + "_HealthLabel"
			health_label.text = "Health: "
			health_container.add_child(health_label)
			health_label.owner = current_scene
			
			# Score (top right)
			var score_label = Label.new()
			score_label.name = name_prefix + "_Score"
			score_label.text = "Score: 0"
			score_label.anchor_left = 1.0
			score_label.anchor_right = 1.0
			score_label.position = Vector2(-100, 20)
			hud_container.add_child(score_label)
			score_label.owner = current_scene
			
			created_nodes.append_array([hud_container.name, health_container.name, health_label.name, score_label.name])
		
		"dialog":
			var title = customization.get("title", "Dialog")
			
			# Create dialog background
			var dialog_panel = Panel.new()
			dialog_panel.name = name_prefix + "_Panel"
			parent_node.add_child(dialog_panel)
			dialog_panel.owner = current_scene
			
			# Center dialog
			dialog_panel.anchor_left = 0.5
			dialog_panel.anchor_right = 0.5
			dialog_panel.anchor_top = 0.5
			dialog_panel.anchor_bottom = 0.5
			dialog_panel.offset_left = -200
			dialog_panel.offset_right = 200
			dialog_panel.offset_top = -150
			dialog_panel.offset_bottom = 150
			
			# Create content container
			var content_container = VBoxContainer.new()
			content_container.name = name_prefix + "_Content"
			content_container.anchor_left = 0.0
			content_container.anchor_top = 0.0
			content_container.anchor_right = 1.0
			content_container.anchor_bottom = 1.0
			content_container.offset_left = 20
			content_container.offset_top = 20
			content_container.offset_right = -20
			content_container.offset_bottom = -20
			dialog_panel.add_child(content_container)
			content_container.owner = current_scene
			
			# Title
			var title_label = Label.new()
			title_label.name = name_prefix + "_Title"
			title_label.text = title
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content_container.add_child(title_label)
			title_label.owner = current_scene
			
			# OK button
			var ok_button = Button.new()
			ok_button.name = name_prefix + "_OK"
			ok_button.text = "OK"
			content_container.add_child(ok_button)
			ok_button.owner = current_scene
			
			created_nodes.append_array([dialog_panel.name, content_container.name, title_label.name, ok_button.name])
		
		"button_row":
			var buttons = customization.get("buttons", ["Button1", "Button2", "Button3"])
			
			# Create horizontal container
			var button_container = HBoxContainer.new()
			button_container.name = name_prefix + "_ButtonRow"
			parent_node.add_child(button_container)
			button_container.owner = current_scene
			
			# Center the row
			button_container.anchor_left = 0.5
			button_container.anchor_right = 0.5
			button_container.anchor_top = 0.5
			button_container.anchor_bottom = 0.5
			button_container.offset_left = -150
			button_container.offset_right = 150
			button_container.offset_top = -25
			button_container.offset_bottom = 25
			button_container.add_theme_constant_override("separation", 10)
			
			# Create buttons
			for button_text in buttons:
				var button = Button.new()
				button.name = name_prefix + "_" + button_text.replace(" ", "")
				button.text = button_text
				button_container.add_child(button)
				button.owner = current_scene
				created_nodes.append(button.name)
			
			created_nodes.append(button_container.name)
		
		_:
			return {
				"status": 400,
				"body": {
					"success": false,
					"error": "Unknown UI pattern: " + pattern
				}
			}
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"pattern": pattern,
			"created_nodes": created_nodes,
			"message": "UI pattern applied successfully"
		}
	}

# UI Layout Management functions
func create_ui_layout(params: Dictionary) -> Dictionary:
	var container_type = params.get("container_type", "VBoxContainer")
	var name = params.get("name", "Container")
	var parent_path = params.get("parent_path", "")
	var positioning = params.get("positioning", "centered")
	var x = params.get("x")
	var y = params.get("y")
	var width = params.get("width")
	var height = params.get("height")
	var spacing = params.get("spacing")
	var columns = params.get("columns")
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene currently open"
			}
		}
	
	# Get parent node
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
	
	# Create the container
	var container = _create_node_by_type(container_type)
	if not container:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Invalid container type: " + container_type
			}
		}
	
	container.name = name
	parent_node.add_child(container)
	container.owner = current_scene
	
	# Configure container-specific properties
	if spacing != null and container.has_method("add_theme_constant_override"):
		if container_type in ["VBoxContainer", "HBoxContainer"]:
			container.add_theme_constant_override("separation", int(spacing))
	
	if columns != null and container_type == "GridContainer":
		container.columns = int(columns)
	
	# Position the container based on positioning type
	if container is Control:
		var control_container = container as Control
		
		match positioning:
			"centered":
				control_container.anchor_left = 0.5
				control_container.anchor_right = 0.5
				control_container.anchor_top = 0.5
				control_container.anchor_bottom = 0.5
				if width != null and height != null:
					control_container.size = Vector2(width, height)
					control_container.offset_left = -width / 2
					control_container.offset_right = width / 2
					control_container.offset_top = -height / 2
					control_container.offset_bottom = height / 2
			
			"fullscreen":
				control_container.anchor_left = 0.0
				control_container.anchor_top = 0.0
				control_container.anchor_right = 1.0
				control_container.anchor_bottom = 1.0
				control_container.offset_left = 0
				control_container.offset_top = 0
				control_container.offset_right = 0
				control_container.offset_bottom = 0
			
			"top_left":
				control_container.anchor_left = 0.0
				control_container.anchor_top = 0.0
				control_container.anchor_right = 0.0
				control_container.anchor_bottom = 0.0
				if width != null and height != null:
					control_container.size = Vector2(width, height)
			
			"top_right":
				control_container.anchor_left = 1.0
				control_container.anchor_top = 0.0
				control_container.anchor_right = 1.0
				control_container.anchor_bottom = 0.0
				if width != null and height != null:
					control_container.size = Vector2(width, height)
					control_container.offset_left = -width
					control_container.offset_right = 0
			
			"bottom_left":
				control_container.anchor_left = 0.0
				control_container.anchor_top = 1.0
				control_container.anchor_right = 0.0
				control_container.anchor_bottom = 1.0
				if width != null and height != null:
					control_container.size = Vector2(width, height)
					control_container.offset_top = -height
					control_container.offset_bottom = 0
			
			"bottom_right":
				control_container.anchor_left = 1.0
				control_container.anchor_top = 1.0
				control_container.anchor_right = 1.0
				control_container.anchor_bottom = 1.0
				if width != null and height != null:
					control_container.size = Vector2(width, height)
					control_container.offset_left = -width
					control_container.offset_right = 0
					control_container.offset_top = -height
					control_container.offset_bottom = 0
			
			"custom":
				if x != null and y != null:
					control_container.position = Vector2(x, y)
				if width != null and height != null:
					control_container.size = Vector2(width, height)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"container_path": container.get_path(),
			"container_type": container_type,
			"positioning": positioning,
			"message": "UI layout container created successfully"
		}
	}

func set_anchor_preset(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var preset = params.get("preset", "")
	var keep_offsets = params.get("keep_offsets", false)
	
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
	
	if not target_node is Control:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node is not a Control node: " + node_path
			}
		}
	
	var control_node = target_node as Control
	var original_size = control_node.size
	var original_position = control_node.position
	
	# Apply the anchor preset
	_apply_anchor_preset_extended(control_node, preset)
	
	# Restore size and position if keep_offsets is true
	if keep_offsets:
		control_node.size = original_size
		control_node.position = original_position
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"node_path": node_path,
			"preset": preset,
			"keep_offsets": keep_offsets,
			"message": "Anchor preset applied successfully"
		}
	}

func _apply_anchor_preset_extended(control: Control, preset: String):
	match preset:
		"top_left":
			control.anchor_left = 0.0
			control.anchor_top = 0.0
			control.anchor_right = 0.0
			control.anchor_bottom = 0.0
		"top_right":
			control.anchor_left = 1.0
			control.anchor_top = 0.0
			control.anchor_right = 1.0
			control.anchor_bottom = 0.0
		"bottom_left":
			control.anchor_left = 0.0
			control.anchor_top = 1.0
			control.anchor_right = 0.0
			control.anchor_bottom = 1.0
		"bottom_right":
			control.anchor_left = 1.0
			control.anchor_top = 1.0
			control.anchor_right = 1.0
			control.anchor_bottom = 1.0
		"center_left":
			control.anchor_left = 0.0
			control.anchor_top = 0.5
			control.anchor_right = 0.0
			control.anchor_bottom = 0.5
		"center_top":
			control.anchor_left = 0.5
			control.anchor_top = 0.0
			control.anchor_right = 0.5
			control.anchor_bottom = 0.0
		"center_right":
			control.anchor_left = 1.0
			control.anchor_top = 0.5
			control.anchor_right = 1.0
			control.anchor_bottom = 0.5
		"center_bottom":
			control.anchor_left = 0.5
			control.anchor_top = 1.0
			control.anchor_right = 0.5
			control.anchor_bottom = 1.0
		"center":
			control.anchor_left = 0.5
			control.anchor_top = 0.5
			control.anchor_right = 0.5
			control.anchor_bottom = 0.5
		"left_wide":
			control.anchor_left = 0.0
			control.anchor_top = 0.0
			control.anchor_right = 0.0
			control.anchor_bottom = 1.0
		"top_wide":
			control.anchor_left = 0.0
			control.anchor_top = 0.0
			control.anchor_right = 1.0
			control.anchor_bottom = 0.0
		"right_wide":
			control.anchor_left = 1.0
			control.anchor_top = 0.0
			control.anchor_right = 1.0
			control.anchor_bottom = 1.0
		"bottom_wide":
			control.anchor_left = 0.0
			control.anchor_top = 1.0
			control.anchor_right = 1.0
			control.anchor_bottom = 1.0
		"vcenter_wide":
			control.anchor_left = 0.0
			control.anchor_top = 0.5
			control.anchor_right = 1.0
			control.anchor_bottom = 0.5
		"hcenter_wide":
			control.anchor_left = 0.5
			control.anchor_top = 0.0
			control.anchor_right = 0.5
			control.anchor_bottom = 1.0
		"full_rect":
			control.anchor_left = 0.0
			control.anchor_top = 0.0
			control.anchor_right = 1.0
			control.anchor_bottom = 1.0

func align_controls(params: Dictionary) -> Dictionary:
	var node_paths = params.get("node_paths", [])
	var alignment = params.get("alignment", "")
	var reference = params.get("reference", "first")
	
	if node_paths.size() < 2:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "At least 2 nodes are required for alignment"
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
	
	# Get all control nodes
	var control_nodes = []
	for node_path in node_paths:
		var node = current_scene.get_node_or_null(node_path)
		if not node:
			return {
				"status": 404,
				"body": {
					"success": false,
					"error": "Node not found: " + node_path
				}
			}
		
		if not node is Control:
			return {
				"status": 400,
				"body": {
					"success": false,
					"error": "Node is not a Control node: " + node_path
				}
			}
		
		control_nodes.append(node)
	
	# Calculate reference position
	var reference_pos = Vector2.ZERO
	var reference_size = Vector2.ZERO
	
	match reference:
		"first":
			reference_pos = control_nodes[0].position
			reference_size = control_nodes[0].size
		"last":
			reference_pos = control_nodes[-1].position
			reference_size = control_nodes[-1].size
		"parent":
			var parent = control_nodes[0].get_parent()
			if parent is Control:
				var parent_control = parent as Control
				reference_pos = Vector2.ZERO
				reference_size = parent_control.size
			else:
				reference_pos = Vector2.ZERO
				reference_size = Vector2(1024, 600)  # Default fallback size
	
	# Apply alignment
	for i in range(control_nodes.size()):
		var control = control_nodes[i] as Control
		var new_position = control.position
		
		match alignment:
			"left":
				new_position.x = reference_pos.x
			"center", "center_horizontal":
				new_position.x = reference_pos.x + (reference_size.x - control.size.x) / 2
			"right":
				new_position.x = reference_pos.x + reference_size.x - control.size.x
			"top":
				new_position.y = reference_pos.y
			"middle", "center_vertical":
				new_position.y = reference_pos.y + (reference_size.y - control.size.y) / 2
			"bottom":
				new_position.y = reference_pos.y + reference_size.y - control.size.y
		
		control.position = new_position
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"aligned_nodes": node_paths.size(),
			"alignment": alignment,
			"reference": reference,
			"message": "Controls aligned successfully"
		}
	}

func distribute_controls(params: Dictionary) -> Dictionary:
	var node_paths = params.get("node_paths", [])
	var direction = params.get("direction", "")
	var spacing = params.get("spacing")
	var start_position = params.get("start_position")
	var end_position = params.get("end_position")
	
	if node_paths.size() < 3:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "At least 3 nodes are required for distribution"
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
	
	# Get all control nodes
	var control_nodes = []
	for node_path in node_paths:
		var node = current_scene.get_node_or_null(node_path)
		if not node:
			return {
				"status": 404,
				"body": {
					"success": false,
					"error": "Node not found: " + node_path
				}
			}
		
		if not node is Control:
			return {
				"status": 400,
				"body": {
					"success": false,
					"error": "Node is not a Control node: " + node_path
				}
			}
		
		control_nodes.append(node)
	
	# Calculate distribution
	var actual_spacing = 0.0
	
	if direction == "horizontal":
		# Calculate bounds
		var min_x = start_position if start_position != null else control_nodes[0].position.x
		var max_x = end_position if end_position != null else control_nodes[-1].position.x + control_nodes[-1].size.x
		
		if spacing != null:
			# Use specified spacing
			actual_spacing = spacing
			var current_x = min_x
			for control in control_nodes:
				control.position.x = current_x
				current_x += control.size.x + actual_spacing
		else:
			# Calculate even distribution
			var total_width = 0.0
			for control in control_nodes:
				total_width += control.size.x
			
			var available_space = max_x - min_x - total_width
			actual_spacing = available_space / (control_nodes.size() - 1)
			
			var current_x = min_x
			for control in control_nodes:
				control.position.x = current_x
				current_x += control.size.x + actual_spacing
	
	elif direction == "vertical":
		# Calculate bounds
		var min_y = start_position if start_position != null else control_nodes[0].position.y
		var max_y = end_position if end_position != null else control_nodes[-1].position.y + control_nodes[-1].size.y
		
		if spacing != null:
			# Use specified spacing
			actual_spacing = spacing
			var current_y = min_y
			for control in control_nodes:
				control.position.y = current_y
				current_y += control.size.y + actual_spacing
		else:
			# Calculate even distribution
			var total_height = 0.0
			for control in control_nodes:
				total_height += control.size.y
			
			var available_space = max_y - min_y - total_height
			actual_spacing = available_space / (control_nodes.size() - 1)
			
			var current_y = min_y
			for control in control_nodes:
				control.position.y = current_y
				current_y += control.size.y + actual_spacing
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"distributed_nodes": node_paths.size(),
			"direction": direction,
			"actual_spacing": actual_spacing,
			"message": "Controls distributed successfully"
		}
	}