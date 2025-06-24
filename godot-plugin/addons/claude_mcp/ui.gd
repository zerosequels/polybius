@tool
extends Node
class_name UIAPI

# Load ui themes
load(script_path + "/ui_themes.gd")

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

