@tool
extends Node
class_name AssetsAPI

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
