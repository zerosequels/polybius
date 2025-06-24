@tool
extends Node
class_name UIThemeAPI

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
