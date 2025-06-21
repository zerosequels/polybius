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
	# Use ClassDB to dynamically create any valid Godot node type
	if ClassDB.class_exists(type):
		# Check if the class can be instantiated (not abstract)
		if ClassDB.can_instantiate(type):
			# Verify it's a Node-derived class
			if ClassDB.is_parent_class(type, "Node"):
				return ClassDB.instantiate(type)
			else:
				print("Warning: Class '" + type + "' is not a Node-derived class")
				return null
		else:
			print("Warning: Class '" + type + "' cannot be instantiated (likely abstract)")
			return null
	else:
		print("Warning: Class '" + type + "' does not exist in Godot")
		return null

# Node documentation and discovery functions
func get_node_class_info(params: Dictionary) -> Dictionary:
	var class_name = params.get("class_name", "")
	
	if class_name.is_empty():
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Class name is required"
			}
		}
	
	if not ClassDB.class_exists(class_name):
		# Try to find similar class names
		var all_classes = ClassDB.get_class_list()
		var suggestions = []
		for cls in all_classes:
			if cls.to_lower().contains(class_name.to_lower()) or class_name.to_lower().contains(cls.to_lower()):
				suggestions.append(cls)
		
		var error_msg = "Class '" + class_name + "' does not exist in Godot"
		if suggestions.size() > 0:
			error_msg += ". Did you mean: " + ", ".join(suggestions.slice(0, 5))
		
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": error_msg,
				"suggestions": suggestions.slice(0, 10)
			}
		}
	
	var info = {
		"class_name": class_name,
		"exists": true,
		"can_instantiate": ClassDB.can_instantiate(class_name),
		"is_node": ClassDB.is_parent_class(class_name, "Node"),
		"parent_class": ClassDB.get_parent_class(class_name),
		"child_classes": [],
		"properties": [],
		"methods": []
	}
	
	# Get child classes
	var all_classes = ClassDB.get_class_list()
	for cls in all_classes:
		if ClassDB.get_parent_class(cls) == class_name:
			info.child_classes.append(cls)
	
	# Get class methods
	var methods = ClassDB.class_get_method_list(class_name, true)
	for method in methods:
		info.methods.append(method.name)
	
	# Get class properties
	var properties = ClassDB.class_get_property_list(class_name, true)
	for prop in properties:
		if prop.usage & PROPERTY_USAGE_STORAGE:  # Only include storable properties
			info.properties.append({
				"name": prop.name,
				"type": _type_to_string(prop.type),
				"usage": prop.usage
			})
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"info": info
		}
	}

func list_node_classes(params: Dictionary) -> Dictionary:
	var filter_type = params.get("filter", "all")  # all, node, control, node2d, node3d
	var search_term = params.get("search", "")
	
	var all_classes = ClassDB.get_class_list()
	var filtered_classes = []
	
	for cls in all_classes:
		var include_class = false
		
		# Apply filter
		match filter_type:
			"all":
				include_class = true
			"node":
				include_class = ClassDB.is_parent_class(cls, "Node")
			"control":
				include_class = ClassDB.is_parent_class(cls, "Control")
			"node2d":
				include_class = ClassDB.is_parent_class(cls, "Node2D")
			"node3d":
				include_class = ClassDB.is_parent_class(cls, "Node3D")
			_:
				include_class = ClassDB.is_parent_class(cls, filter_type)
		
		# Apply search term
		if include_class and not search_term.is_empty():
			include_class = cls.to_lower().contains(search_term.to_lower())
		
		if include_class:
			filtered_classes.append({
				"name": cls,
				"parent": ClassDB.get_parent_class(cls),
				"can_instantiate": ClassDB.can_instantiate(cls),
				"is_node": ClassDB.is_parent_class(cls, "Node")
			})
	
	# Sort by name
	filtered_classes.sort_custom(func(a, b): return a.name < b.name)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"classes": filtered_classes,
			"total_count": filtered_classes.size(),
			"filter": filter_type,
			"search": search_term
		}
	}

# Helper function to convert Godot's type enum to string
func _type_to_string(type: int) -> String:
	match type:
		TYPE_NIL: return "nil"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR2I: return "Vector2i"
		TYPE_RECT2: return "Rect2"
		TYPE_RECT2I: return "Rect2i"
		TYPE_VECTOR3: return "Vector3"
		TYPE_VECTOR3I: return "Vector3i"
		TYPE_TRANSFORM2D: return "Transform2D"
		TYPE_VECTOR4: return "Vector4"
		TYPE_VECTOR4I: return "Vector4i"
		TYPE_PLANE: return "Plane"
		TYPE_QUATERNION: return "Quaternion"
		TYPE_AABB: return "AABB"
		TYPE_BASIS: return "Basis"
		TYPE_TRANSFORM3D: return "Transform3D"
		TYPE_PROJECTION: return "Projection"
		TYPE_COLOR: return "Color"
		TYPE_STRING_NAME: return "StringName"
		TYPE_NODE_PATH: return "NodePath"
		TYPE_RID: return "RID"
		TYPE_OBJECT: return "Object"
		TYPE_CALLABLE: return "Callable"
		TYPE_SIGNAL: return "Signal"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		_: return "Unknown"

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

# =============================================================================
# THEME MANAGEMENT FUNCTIONS
# =============================================================================

func create_theme(params: Dictionary) -> Dictionary:
	var theme_name = params.get("name", "NewTheme")
	var theme_path = params.get("path", "res://themes/%s.tres" % theme_name)
	var base_theme = params.get("base_theme", "")
	var properties = params.get("properties", {})
	
	# Ensure themes directory exists
	var dir = DirAccess.open("res://")
	var themes_dir = theme_path.get_base_dir()
	if not dir.dir_exists(themes_dir.replace("res://", "")):
		var make_dir_error = dir.make_dir_recursive(themes_dir.replace("res://", ""))
		if make_dir_error != OK:
			return {
				"status": 500,
				"body": {
					"success": false,
					"error": "Failed to create themes directory: " + str(make_dir_error)
				}
			}
	
	# Create new theme
	var theme = Theme.new()
	
	# Apply base theme if specified
	if base_theme != "":
		var base_theme_resource = null
		if base_theme == "default_theme":
			base_theme_resource = ThemeDB.get_default_theme()
		elif base_theme == "editor_theme":
			# Use editor theme if available
			if EditorInterface.get_editor_theme():
				base_theme_resource = EditorInterface.get_editor_theme()
		else:
			# Try to load as file path
			if ResourceLoader.exists(base_theme):
				base_theme_resource = load(base_theme)
		
		if base_theme_resource and base_theme_resource is Theme:
			# Copy properties from base theme
			_copy_theme_properties(base_theme_resource, theme)
	
	# Apply initial properties
	if properties.size() > 0:
		_apply_theme_properties(theme, properties)
	
	# Save theme
	var save_error = ResourceSaver.save(theme, theme_path)
	if save_error != OK:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to save theme: " + str(save_error)
			}
		}
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"path": theme_path,
			"name": theme_name,
			"base_theme": base_theme,
			"properties_applied": properties.size(),
			"message": "Theme created successfully"
		}
	}

func apply_theme(params: Dictionary) -> Dictionary:
	var theme_path = params.get("theme_path", "")
	var target = params.get("target", "scene")
	var node_path = params.get("node_path", "")
	var recursive = params.get("recursive", true)
	
	if theme_path == "":
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "theme_path is required"
			}
		}
	
	# Load theme
	if not ResourceLoader.exists(theme_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Theme not found: " + theme_path
			}
		}
	
	var theme = load(theme_path)
	if not theme is Theme:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Invalid theme resource: " + theme_path
			}
		}
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene is currently open"
			}
		}
	
	var nodes_affected = 0
	var applied_to = ""
	
	if target == "scene":
		# Apply to all Control nodes in scene
		nodes_affected = _apply_theme_to_node(current_scene, theme, recursive)
		applied_to = "entire scene"
	else:
		# Apply to specific node
		var target_node = current_scene.get_node_or_null(NodePath(node_path))
		if not target_node:
			return {
				"status": 404,
				"body": {
					"success": false,
					"error": "Node not found: " + node_path
				}
			}
		
		nodes_affected = _apply_theme_to_node(target_node, theme, recursive)
		applied_to = "node: " + node_path
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"applied_to": applied_to,
			"nodes_affected": nodes_affected,
			"theme_path": theme_path,
			"message": "Theme applied successfully"
		}
	}

func modify_theme_properties(params: Dictionary) -> Dictionary:
	var theme_path = params.get("theme_path", "")
	var properties = params.get("properties", {})
	var remove_properties = params.get("remove_properties", [])
	
	if theme_path == "":
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "theme_path is required"
			}
		}
	
	# Load theme
	if not ResourceLoader.exists(theme_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Theme not found: " + theme_path
			}
		}
	
	var theme = load(theme_path)
	if not theme is Theme:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Invalid theme resource: " + theme_path
			}
		}
	
	var properties_modified = 0
	var properties_removed = 0
	
	# Apply new properties
	if properties.size() > 0:
		properties_modified = _apply_theme_properties(theme, properties)
	
	# Remove properties if specified
	if remove_properties.size() > 0:
		properties_removed = _remove_theme_properties(theme, remove_properties)
	
	# Save theme
	var save_error = ResourceSaver.save(theme, theme_path)
	if save_error != OK:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to save theme: " + str(save_error)
			}
		}
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"properties_modified": properties_modified,
			"properties_removed": properties_removed,
			"theme_path": theme_path,
			"message": "Theme properties modified successfully"
		}
	}

func import_theme(params: Dictionary) -> Dictionary:
	var source_path = params.get("source_path", "")
	var target_path = params.get("target_path", "res://themes/")
	var theme_name = params.get("theme_name", "")
	var overwrite = params.get("overwrite", false)
	
	if source_path == "":
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "source_path is required"
			}
		}
	
	# Check if source file exists
	var file = FileAccess.open(source_path, FileAccess.READ)
	if not file:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Source file not found: " + source_path
			}
		}
	file.close()
	
	# Determine theme name if not provided
	if theme_name == "":
		theme_name = source_path.get_file().get_basename()
	
	# Ensure target directory exists
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(target_path.replace("res://", "")):
		var make_dir_error = dir.make_dir_recursive(target_path.replace("res://", ""))
		if make_dir_error != OK:
			return {
				"status": 500,
				"body": {
					"success": false,
					"error": "Failed to create target directory: " + str(make_dir_error)
				}
			}
	
	# Construct full target path
	var imported_path = target_path.path_join(theme_name + ".tres")
	
	# Check if target already exists
	if FileAccess.file_exists(imported_path) and not overwrite:
		return {
			"status": 409,
			"body": {
				"success": false,
				"error": "Theme already exists: " + imported_path + ". Use overwrite=true to replace."
			}
		}
	
	# Copy file
	var copy_error = dir.copy(source_path, imported_path)
	if copy_error != OK:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to copy theme file: " + str(copy_error)
			}
		}
	
	# Refresh filesystem
	EditorInterface.get_resource_filesystem().scan()
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"imported_path": imported_path,
			"source": source_path,
			"theme_name": theme_name,
			"message": "Theme imported successfully"
		}
	}

func export_theme(params: Dictionary) -> Dictionary:
	var theme_path = params.get("theme_path", "")
	var export_path = params.get("export_path", "")
	var format = params.get("format", "tres")
	var include_dependencies = params.get("include_dependencies", true)
	
	if theme_path == "":
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "theme_path is required"
			}
		}
	
	if export_path == "":
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "export_path is required"
			}
		}
	
	# Load theme
	if not ResourceLoader.exists(theme_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Theme not found: " + theme_path
			}
		}
	
	var theme = load(theme_path)
	if not theme is Theme:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Invalid theme resource: " + theme_path
			}
		}
	
	# Ensure export path has correct extension
	if not export_path.ends_with("." + format):
		export_path += "." + format
	
	# Save theme to export location
	var save_error = ResourceSaver.save(theme, export_path)
	if save_error != OK:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to export theme: " + str(save_error)
			}
		}
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"exported_path": export_path,
			"source": theme_path,
			"format": format,
			"message": "Theme exported successfully"
		}
	}

func list_themes(params: Dictionary) -> Dictionary:
	var directory = params.get("directory", "res://")
	var recursive = params.get("recursive", true)
	
	var themes = []
	_find_theme_files(directory, themes, recursive)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"themes": themes,
			"count": themes.size(),
			"directory": directory,
			"recursive": recursive
		}
	}

func get_theme_properties(params: Dictionary) -> Dictionary:
	var theme_path = params.get("theme_path", "")
	var property_type = params.get("property_type", "all")
	
	if theme_path == "":
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "theme_path is required"
			}
		}
	
	# Load theme
	if not ResourceLoader.exists(theme_path):
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Theme not found: " + theme_path
			}
		}
	
	var theme = load(theme_path)
	if not theme is Theme:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Invalid theme resource: " + theme_path
			}
		}
	
	var properties = {}
	
	if property_type == "all" or property_type == "colors":
		properties["colors"] = _get_theme_colors(theme)
	
	if property_type == "all" or property_type == "fonts":
		properties["fonts"] = _get_theme_fonts(theme)
	
	if property_type == "all" or property_type == "font_sizes":
		properties["font_sizes"] = _get_theme_font_sizes(theme)
	
	if property_type == "all" or property_type == "icons":
		properties["icons"] = _get_theme_icons(theme)
	
	if property_type == "all" or property_type == "styles":
		properties["styles"] = _get_theme_styles(theme)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"properties": properties,
			"theme_path": theme_path,
			"property_type": property_type
		}
	}

# =============================================================================
# THEME HELPER FUNCTIONS
# =============================================================================

func _copy_theme_properties(source_theme: Theme, target_theme: Theme):
	# This is a simplified copy - in practice you'd want to copy all theme types
	# For now, we'll copy basic properties that are commonly used
	var theme_types = [
		"Button", "Label", "LineEdit", "TextEdit", "Panel", "PanelContainer",
		"VBoxContainer", "HBoxContainer", "GridContainer", "ScrollContainer"
	]
	
	for theme_type in theme_types:
		# Copy colors
		for color_name in ["font_color", "font_color_hover", "font_color_pressed", "font_color_disabled"]:
			if source_theme.has_color(color_name, theme_type):
				target_theme.set_color(color_name, theme_type, source_theme.get_color(color_name, theme_type))

func _apply_theme_properties(theme: Theme, properties: Dictionary) -> int:
	var applied_count = 0
	
	# Apply default font size
	if properties.has("default_font_size"):
		theme.default_font_size = properties["default_font_size"]
		applied_count += 1
	
	# Apply colors
	if properties.has("colors"):
		var colors = properties["colors"]
		for color_key in colors.keys():
			var parts = color_key.split("/")
			if parts.size() == 2:
				var color_name = parts[0]
				var theme_type = parts[1]
				var color_value = Color(colors[color_key])
				theme.set_color(color_name, theme_type, color_value)
				applied_count += 1
	
	# Apply font sizes
	if properties.has("font_sizes"):
		var font_sizes = properties["font_sizes"]
		for size_key in font_sizes.keys():
			var parts = size_key.split("/")
			if parts.size() == 2:
				var size_name = parts[0]
				var theme_type = parts[1]
				theme.set_font_size(size_name, theme_type, font_sizes[size_key])
				applied_count += 1
	
	return applied_count

func _remove_theme_properties(theme: Theme, property_names: Array) -> int:
	var removed_count = 0
	
	for property_name in property_names:
		var parts = property_name.split("/")
		if parts.size() >= 2:
			var prop_name = parts[0]
			var theme_type = parts[1]
			
			# Try to remove as different property types
			if theme.has_color(prop_name, theme_type):
				theme.clear_color(prop_name, theme_type)
				removed_count += 1
			elif theme.has_font_size(prop_name, theme_type):
				theme.clear_font_size(prop_name, theme_type)
				removed_count += 1
	
	return removed_count

func _apply_theme_to_node(node: Node, theme: Theme, recursive: bool) -> int:
	var count = 0
	
	if node is Control:
		node.theme = theme
		count += 1
	
	if recursive:
		for child in node.get_children():
			count += _apply_theme_to_node(child, theme, recursive)
	
	return count

func _find_theme_files(directory: String, themes: Array, recursive: bool):
	var dir = DirAccess.open(directory)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = directory.path_join(file_name)
		
		if dir.current_is_dir() and recursive and file_name != "." and file_name != "..":
			_find_theme_files(full_path, themes, recursive)
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			# Check if it's a theme resource
			if ResourceLoader.exists(full_path):
				var resource = load(full_path)
				if resource is Theme:
					var file_access = FileAccess.open(full_path, FileAccess.READ)
					var size = file_access.get_length() if file_access else 0
					if file_access:
						file_access.close()
					
					themes.append({
						"name": file_name.get_basename(),
						"path": full_path,
						"size": str(size) + " bytes"
					})
		
		file_name = dir.get_next()

func _get_theme_colors(theme: Theme) -> Dictionary:
	var colors = {}
	# This is simplified - you'd want to iterate through all theme types
	var common_types = ["Button", "Label", "LineEdit", "Panel"]
	var common_colors = ["font_color", "font_color_hover", "font_color_pressed"]
	
	for theme_type in common_types:
		for color_name in common_colors:
			if theme.has_color(color_name, theme_type):
				colors[color_name + "/" + theme_type] = str(theme.get_color(color_name, theme_type))
	
	return colors

func _get_theme_fonts(theme: Theme) -> Dictionary:
	var fonts = {}
	var common_types = ["Button", "Label", "LineEdit"]
	
	for theme_type in common_types:
		if theme.has_font("font", theme_type):
			var font = theme.get_font("font", theme_type)
			fonts["font/" + theme_type] = font.resource_path if font else "built-in"
	
	return fonts

func _get_theme_font_sizes(theme: Theme) -> Dictionary:
	var font_sizes = {}
	var common_types = ["Button", "Label", "LineEdit"]
	
	for theme_type in common_types:
		if theme.has_font_size("font_size", theme_type):
			font_sizes["font_size/" + theme_type] = theme.get_font_size("font_size", theme_type)
	
	return font_sizes

func _get_theme_icons(theme: Theme) -> Dictionary:
	var icons = {}
	# Icons are mainly used in buttons and some other controls
	if theme.has_icon("icon", "Button"):
		var icon = theme.get_icon("icon", "Button")
		icons["icon/Button"] = icon.resource_path if icon else "built-in"
	
	return icons

func _get_theme_styles(theme: Theme) -> Dictionary:
	var styles = {}
	var common_types = ["Button", "Panel", "LineEdit"]
	var common_styles = ["normal", "hover", "pressed", "disabled"]
	
	for theme_type in common_types:
		for style_name in common_styles:
			if theme.has_stylebox(style_name, theme_type):
				var style = theme.get_stylebox(style_name, theme_type)
				styles[style_name + "/" + theme_type] = str(style.get_class()) if style else "null"
	
	return styles

# =============================================================================
# ANIMATION & INTERACTION FUNCTIONS
# =============================================================================

func create_ui_animation(params: Dictionary) -> Dictionary:
	var target_node_path = params.get("target_node_path", "")
	var animation_name = params.get("animation_name", "UIAnimation")
	var animation_type = params.get("animation_type", "fade_in")
	var duration = params.get("duration", 1.0)
	var easing = params.get("easing", "ease_out")
	var direction = params.get("direction", "left")
	var custom_properties = params.get("custom_properties", {})
	var auto_start = params.get("auto_start", false)
	var loop = params.get("loop", false)
	
	if target_node_path == "":
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "target_node_path is required"
			}
		}
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene is currently open"
			}
		}
	
	# Find target node
	var target_node = current_scene.get_node_or_null(NodePath(target_node_path))
	if not target_node:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Target node not found: " + target_node_path
			}
		}
	
	if not target_node is Control:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Target node must be a Control node for UI animation"
			}
		}
	
	# Create Tween node
	var tween = Tween.new()
	tween.name = animation_name
	target_node.add_child(tween)
	tween.owner = current_scene
	
	# Configure tween based on animation type
	var easing_type = _get_tween_easing(easing)
	var trans_type = Tween.TRANS_SINE
	
	match animation_type:
		"fade_in":
			target_node.modulate.a = 0.0
			tween.tween_property(target_node, "modulate:a", 1.0, duration)
			tween.tween_set_ease(easing_type)
			tween.tween_set_trans(trans_type)
		
		"fade_out":
			target_node.modulate.a = 1.0
			tween.tween_property(target_node, "modulate:a", 0.0, duration)
			tween.tween_set_ease(easing_type)
			tween.tween_set_trans(trans_type)
		
		"slide_in":
			var start_position = _get_slide_start_position(target_node, direction)
			var end_position = target_node.position
			target_node.position = start_position
			tween.tween_property(target_node, "position", end_position, duration)
			tween.tween_set_ease(easing_type)
			tween.tween_set_trans(trans_type)
		
		"slide_out":
			var start_position = target_node.position
			var end_position = _get_slide_end_position(target_node, direction)
			tween.tween_property(target_node, "position", end_position, duration)
			tween.tween_set_ease(easing_type)
			tween.tween_set_trans(trans_type)
		
		"scale_up":
			target_node.scale = Vector2.ZERO
			tween.tween_property(target_node, "scale", Vector2.ONE, duration)
			tween.tween_set_ease(easing_type)
			tween.tween_set_trans(trans_type)
		
		"scale_down":
			target_node.scale = Vector2.ONE
			tween.tween_property(target_node, "scale", Vector2.ZERO, duration)
			tween.tween_set_ease(easing_type)
			tween.tween_set_trans(trans_type)
		
		"rotate":
			var start_rotation = target_node.rotation
			var end_rotation = start_rotation + (PI * 2)  # Full rotation
			tween.tween_property(target_node, "rotation", end_rotation, duration)
			tween.tween_set_ease(easing_type)
			tween.tween_set_trans(trans_type)
		
		"color_change":
			if target_node.has_method("set_modulate"):
				var start_color = target_node.modulate
				var end_color = Color.RED  # Default color change
				tween.tween_property(target_node, "modulate", end_color, duration)
				tween.tween_set_ease(easing_type)
				tween.tween_set_trans(trans_type)
		
		"custom":
			if custom_properties.has("property_name") and custom_properties.has("from_value") and custom_properties.has("to_value"):
				var property_name = custom_properties["property_name"]
				var from_value = custom_properties["from_value"]
				var to_value = custom_properties["to_value"]
				
				# Set initial value
				target_node.set(property_name, from_value)
				# Animate to target value
				tween.tween_property(target_node, property_name, to_value, duration)
				tween.tween_set_ease(easing_type)
				tween.tween_set_trans(trans_type)
	
	# Configure loop
	if loop:
		tween.set_loops()
	
	# Auto start if requested
	if auto_start:
		tween.play()
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"animation_name": animation_name,
			"animation_type": animation_type,
			"target_node": target_node_path,
			"duration": duration,
			"auto_started": auto_start,
			"message": "UI animation created successfully"
		}
	}

func configure_ui_signals(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var signals = params.get("signals", [])
	var script_path = params.get("script_path", "")
	var auto_attach_script = params.get("auto_attach_script", true)
	
	if node_path == "":
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "node_path is required"
			}
		}
	
	if signals.size() == 0:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "signals array cannot be empty"
			}
		}
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene is currently open"
			}
		}
	
	# Find target node
	var target_node = current_scene.get_node_or_null(NodePath(node_path))
	if not target_node:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Target node not found: " + node_path
			}
		}
	
	var signals_connected = 0
	var methods_created = 0
	var script_content = ""
	var script_resource = null
	
	# Handle script creation/attachment
	if script_path == "":
		script_path = "res://scripts/" + target_node.name + "_signals.gd"
	
	# Create script directory if needed
	var dir = DirAccess.open("res://")
	var script_dir = script_path.get_base_dir()
	if not dir.dir_exists(script_dir.replace("res://", "")):
		dir.make_dir_recursive(script_dir.replace("res://", ""))
	
	# Create or load script
	if FileAccess.file_exists(script_path):
		var file = FileAccess.open(script_path, FileAccess.READ)
		script_content = file.get_as_text()
		file.close()
		script_resource = load(script_path)
	else:
		# Create new script
		script_content = "extends " + target_node.get_class() + "\n\n"
		script_resource = GDScript.new()
		script_resource.source_code = script_content
		ResourceSaver.save(script_resource, script_path)
	
	# Attach script to node if requested
	if auto_attach_script and target_node.get_script() == null:
		target_node.set_script(script_resource)
	
	# Process each signal configuration
	for signal_config in signals:
		var signal_name = signal_config.get("signal_name", "")
		var method_name = signal_config.get("method_name", "")
		var target_node_path = signal_config.get("target_node_path", node_path)
		var create_method = signal_config.get("create_method", true)
		var method_parameters = signal_config.get("method_parameters", [])
		var method_body = signal_config.get("method_body", "")
		
		if signal_name == "" or method_name == "":
			continue
		
		# Find signal receiver node
		var receiver_node = current_scene.get_node_or_null(NodePath(target_node_path))
		if not receiver_node:
			continue
		
		# Check if signal exists on target node
		if not target_node.has_signal(signal_name):
			continue
		
		# Create method in script if requested
		if create_method and not script_content.contains("func " + method_name):
			var param_string = ""
			if method_parameters.size() > 0:
				param_string = method_parameters.join(", ")
			
			if method_body == "":
				method_body = "\tprint(\"" + method_name + " called\")"
			
			var method_definition = "\nfunc " + method_name + "(" + param_string + "):\n" + method_body + "\n"
			script_content += method_definition
			methods_created += 1
		
		# Connect signal
		if not target_node.is_connected(signal_name, Callable(receiver_node, method_name)):
			target_node.connect(signal_name, Callable(receiver_node, method_name))
			signals_connected += 1
	
	# Save updated script
	if methods_created > 0:
		script_resource.source_code = script_content
		ResourceSaver.save(script_resource, script_path)
		
		# Refresh script if attached
		if target_node.get_script() == script_resource:
			target_node.set_script(null)
			target_node.set_script(script_resource)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"signals_connected": signals_connected,
			"methods_created": methods_created,
			"script_path": script_path,
			"node_path": node_path,
			"message": "UI signals configured successfully"
		}
	}

func setup_focus_navigation(params: Dictionary) -> Dictionary:
	var focus_chain = params.get("focus_chain", [])
	var focus_mode = params.get("focus_mode", "all")
	var wrap_around = params.get("wrap_around", true)
	var focus_visual_settings = params.get("focus_visual_settings", {})
	var keyboard_navigation = params.get("keyboard_navigation", {})
	var initial_focus_node = params.get("initial_focus_node", "")
	
	if focus_chain.size() == 0:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "focus_chain cannot be empty"
			}
		}
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene is currently open"
			}
		}
	
	var nodes_configured = 0
	var focus_mode_enum = Control.FOCUS_ALL
	
	# Convert focus mode string to enum
	match focus_mode:
		"none":
			focus_mode_enum = Control.FOCUS_NONE
		"click":
			focus_mode_enum = Control.FOCUS_CLICK
		"all":
			focus_mode_enum = Control.FOCUS_ALL
	
	# Configure focus chain
	var control_nodes = []
	for node_path in focus_chain:
		var node = current_scene.get_node_or_null(NodePath(node_path))
		if node and node is Control:
			control_nodes.append(node)
		else:
			continue
	
	# Set up focus neighbors
	for i in range(control_nodes.size()):
		var current_control = control_nodes[i]
		var next_control = null
		var prev_control = null
		
		# Determine next control
		if i < control_nodes.size() - 1:
			next_control = control_nodes[i + 1]
		elif wrap_around and control_nodes.size() > 1:
			next_control = control_nodes[0]
		
		# Determine previous control
		if i > 0:
			prev_control = control_nodes[i - 1]
		elif wrap_around and control_nodes.size() > 1:
			prev_control = control_nodes[control_nodes.size() - 1]
		
		# Configure focus settings
		current_control.focus_mode = focus_mode_enum
		
		# Set focus neighbors
		if next_control:
			current_control.focus_next = next_control.get_path()
		if prev_control:
			current_control.focus_previous = prev_control.get_path()
		
		# Apply visual settings
		if focus_visual_settings.has("enable_focus_outline") and focus_visual_settings["enable_focus_outline"]:
			# Note: In Godot 4, focus outline is handled through theme
			if focus_visual_settings.has("outline_color"):
				var outline_color = Color(focus_visual_settings["outline_color"])
				# This would need theme configuration in a real implementation
		
		nodes_configured += 1
	
	# Set initial focus
	if initial_focus_node != "":
		var initial_node = current_scene.get_node_or_null(NodePath(initial_focus_node))
		if initial_node and initial_node is Control:
			initial_node.grab_focus()
	elif control_nodes.size() > 0:
		control_nodes[0].grab_focus()
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"nodes_configured": nodes_configured,
			"focus_mode": focus_mode,
			"wrap_around": wrap_around,
			"initial_focus": initial_focus_node if initial_focus_node != "" else focus_chain[0],
			"message": "Focus navigation configured successfully"
		}
	}

func start_ui_animation(params: Dictionary) -> Dictionary:
	var animation_node_path = params.get("animation_node_path", "")
	var action = params.get("action", "start")
	var reverse = params.get("reverse", false)
	var speed_scale = params.get("speed_scale", 1.0)
	
	if animation_node_path == "":
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "animation_node_path is required"
			}
		}
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene is currently open"
			}
		}
	
	# Find animation node (Tween)
	var animation_node = current_scene.get_node_or_null(NodePath(animation_node_path))
	if not animation_node:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Animation node not found: " + animation_node_path
			}
		}
	
	if not animation_node is Tween:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Node is not a Tween animation node"
			}
		}
	
	# Perform action on animation
	match action:
		"start":
			animation_node.play()
		"stop":
			animation_node.stop()
		"pause":
			animation_node.pause()
		"resume":
			animation_node.play()
		"reset":
			animation_node.stop()
			# Reset to initial state would require storing initial values
	
	# Apply speed scale
	if speed_scale != 1.0:
		animation_node.set_speed_scale(speed_scale)
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"action": action,
			"animation_node": animation_node_path,
			"speed_scale": speed_scale,
			"reverse": reverse,
			"message": "Animation control executed successfully"
		}
	}

func create_ui_transition(params: Dictionary) -> Dictionary:
	var transition_name = params.get("transition_name", "")
	var from_state = params.get("from_state", {})
	var to_state = params.get("to_state", {})
	var transition_type = params.get("transition_type", "fade")
	var duration = params.get("duration", 0.5)
	var easing = params.get("easing", "ease_in_out")
	var auto_execute = params.get("auto_execute", false)
	
	if transition_name == "":
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "transition_name is required"
			}
		}
	
	if not from_state.has("node_path") or not to_state.has("node_path"):
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Both from_state and to_state must have node_path"
			}
		}
	
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "No scene is currently open"
			}
		}
	
	# Find nodes
	var from_node = current_scene.get_node_or_null(NodePath(from_state["node_path"]))
	var to_node = current_scene.get_node_or_null(NodePath(to_state["node_path"]))
	
	if not from_node or not to_node:
		return {
			"status": 404,
			"body": {
				"success": false,
				"error": "Could not find from_node or to_node"
			}
		}
	
	if not (from_node is Control and to_node is Control):
		return {
			"status": 400,
			"body": {
				"success": false,
				"error": "Both nodes must be Control nodes for UI transitions"
			}
		}
	
	# Create transition tween
	var transition_tween = Tween.new()
	transition_tween.name = transition_name + "_Transition"
	current_scene.add_child(transition_tween)
	transition_tween.owner = current_scene
	
	var easing_type = _get_tween_easing(easing)
	
	# Set initial states
	if from_state.has("properties"):
		for property_name in from_state["properties"].keys():
			var value = from_state["properties"][property_name]
			from_node.set(property_name, value)
	
	if to_state.has("properties"):
		for property_name in to_state["properties"].keys():
			var value = to_state["properties"][property_name]
			to_node.set(property_name, value)
	
	# Configure transition based on type
	match transition_type:
		"fade":
			from_node.modulate.a = 1.0
			to_node.modulate.a = 0.0
			transition_tween.tween_property(from_node, "modulate:a", 0.0, duration)
			transition_tween.parallel().tween_property(to_node, "modulate:a", 1.0, duration)
		
		"slide":
			# Slide from_node out and to_node in
			var slide_distance = from_node.size.x
			transition_tween.tween_property(from_node, "position:x", -slide_distance, duration)
			transition_tween.parallel().tween_property(to_node, "position:x", 0, duration)
		
		"scale":
			from_node.scale = Vector2.ONE
			to_node.scale = Vector2.ZERO
			transition_tween.tween_property(from_node, "scale", Vector2.ZERO, duration)
			transition_tween.parallel().tween_property(to_node, "scale", Vector2.ONE, duration)
		
		"cross_fade":
			transition_tween.tween_property(from_node, "modulate:a", 0.0, duration)
			transition_tween.parallel().tween_property(to_node, "modulate:a", 1.0, duration)
	
	transition_tween.tween_set_ease(easing_type)
	
	# Auto execute if requested
	if auto_execute:
		transition_tween.play()
	
	return {
		"status": 200,
		"body": {
			"success": true,
			"transition_name": transition_name,
			"transition_type": transition_type,
			"duration": duration,
			"from_node": from_state["node_path"],
			"to_node": to_state["node_path"],
			"auto_executed": auto_execute,
			"message": "UI transition created successfully"
		}
	}

# =============================================================================
# ANIMATION HELPER FUNCTIONS
# =============================================================================

func _get_tween_easing(easing_name: String) -> Tween.EaseType:
	match easing_name:
		"linear":
			return Tween.EASE_IN  # Note: Godot 4 uses different easing system
		"ease_in":
			return Tween.EASE_IN
		"ease_out":
			return Tween.EASE_OUT
		"ease_in_out":
			return Tween.EASE_IN_OUT
		"bounce":
			return Tween.EASE_OUT  # Bounce would need custom implementation
		"elastic":
			return Tween.EASE_OUT  # Elastic would need custom implementation
		_:
			return Tween.EASE_OUT

func _get_slide_start_position(node: Control, direction: String) -> Vector2:
	var viewport_size = get_viewport().get_visible_rect().size
	var start_pos = node.position
	
	match direction:
		"left":
			start_pos.x = -node.size.x
		"right":
			start_pos.x = viewport_size.x
		"up":
			start_pos.y = -node.size.y
		"down":
			start_pos.y = viewport_size.y
	
	return start_pos

func _get_slide_end_position(node: Control, direction: String) -> Vector2:
	var viewport_size = get_viewport().get_visible_rect().size
	var end_pos = node.position
	
	match direction:
		"left":
			end_pos.x = -node.size.x
		"right":
			end_pos.x = viewport_size.x
		"up":
			end_pos.y = -node.size.y
		"down":
			end_pos.y = viewport_size.y
	
	return end_pos