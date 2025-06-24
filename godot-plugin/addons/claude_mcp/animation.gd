@tool
extends Node
class_name AnimationAPI

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