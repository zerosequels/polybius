@tool
extends Node
class_name GodotAPI

func create_scene(params: Dictionary) -> Dictionary:
	var scene_name = params.get("name", "NewScene")
	var scene_path = params.get("path", "res://scenes/%s.tscn" % scene_name)
	
	# Ensure directory exists
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("scenes"):
		dir.make_dir("scenes")
	
	var scene = PackedScene.new()
	var root_node = Node.new()
	root_node.name = scene_name
	scene.pack(root_node)
	
	var error = ResourceSaver.save(scene, scene_path)
	if error == OK:
		EditorInterface.open_scene_from_path(scene_path)
		return {
			"status": 200,
			"body": {
				"success": true,
				"scene_path": scene_path,
				"message": "Scene created successfully"
			}
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
	
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if not file:
		return {
			"status": 500,
			"body": {
				"success": false,
				"error": "Failed to create script file"
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