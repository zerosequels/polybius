@tool
extends Node
class_name ProjectAPI

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
