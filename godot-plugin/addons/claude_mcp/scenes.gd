@tool
extends Node
class_name ScenesAPI

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