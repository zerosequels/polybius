from mcp.types import Tool, TextContent
import json
from typing import Any, Sequence
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from godot_client import GodotClient

# Scene management tools
def get_scene_tools() -> list[Tool]:
    return [
        Tool(
            name="create_scene",
            description="Create a new scene in Godot with specified root node type",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "Name of the new scene"
                    },
                    "path": {
                        "type": "string", 
                        "description": "Optional file path for the scene (defaults to res://scenes/{name}.tscn)"
                    },
                    "root_node_type": {
                        "type": "string",
                        "description": "Type of root node for the scene. Common types: Node2D (for 2D games), Node3D (for 3D games), Control (for UI), Node (generic). If not specified, you MUST ask the user to clarify what type of scene they want to create.",
                        "enum": ["Node2D", "Node3D", "Control", "Node"]
                    },
                    "create_directories": {
                        "type": "boolean",
                        "description": "Whether to create missing directories in the path. If not specified and directory doesn't exist, user will be prompted."
                    }
                },
                "required": ["name"]
            }
        ),
        Tool(
            name="open_scene",
            description="Open an existing scene in Godot",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to the scene file to open"
                    }
                },
                "required": ["path"]
            }
        ),
        Tool(
            name="get_current_scene",
            description="Get information about the currently open scene",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="add_node",
            description="Add a new node to the current scene",
            inputSchema={
                "type": "object",
                "properties": {
                    "type": {
                        "type": "string",
                        "description": "Type of node to create (e.g., Node, Node2D, Control, Label, Button, etc.)"
                    },
                    "name": {
                        "type": "string",
                        "description": "Name for the new node"
                    },
                    "parent_path": {
                        "type": "string",
                        "description": "Path to parent node (empty for scene root)"
                    }
                },
                "required": ["type", "name"]
            }
        ),
        Tool(
            name="list_scenes",
            description="List all scene files in the Godot project",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="duplicate_scene",
            description="Duplicate an existing scene file",
            inputSchema={
                "type": "object",
                "properties": {
                    "source_path": {
                        "type": "string",
                        "description": "Path to the scene file to duplicate"
                    },
                    "target_path": {
                        "type": "string",
                        "description": "Optional target path for the duplicated scene (will auto-generate if not provided)"
                    },
                    "new_name": {
                        "type": "string",
                        "description": "Optional suffix for the duplicated scene name (defaults to 'Copy')"
                    }
                },
                "required": ["source_path"]
            }
        ),
        Tool(
            name="delete_scene",
            description="Delete a scene file from the project",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to the scene file to delete"
                    },
                    "confirm": {
                        "type": "boolean",
                        "description": "Confirmation flag (must be true to proceed with deletion)"
                    }
                },
                "required": ["path", "confirm"]
            }
        ),
        Tool(
            name="delete_node",
            description="Delete a node from the current scene",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the node to delete (e.g., 'Player', 'Player/Sprite2D')"
                    },
                    "confirm": {
                        "type": "boolean",
                        "description": "Confirmation flag (must be true to proceed with deletion)"
                    }
                },
                "required": ["node_path", "confirm"]
            }
        ),
        Tool(
            name="move_node",
            description="Move a node to a new parent or position in the scene tree",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the node to move"
                    },
                    "new_parent_path": {
                        "type": "string",
                        "description": "Path to the new parent node (empty for scene root)"
                    },
                    "new_index": {
                        "type": "integer",
                        "description": "New position index in the parent's children (optional, -1 for end)"
                    }
                },
                "required": ["node_path"]
            }
        ),
        Tool(
            name="get_node_properties",
            description="Get the properties of a node",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the node"
                    }
                },
                "required": ["node_path"]
            }
        ),
        Tool(
            name="set_node_properties",
            description="Set properties of a node",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the node"
                    },
                    "properties": {
                        "type": "object",
                        "description": "Dictionary of property names and values to set"
                    }
                },
                "required": ["node_path", "properties"]
            }
        )
    ]

async def handle_scene_tool(name: str, arguments: dict, godot_client: GodotClient) -> Sequence[TextContent]:
    """Handle scene-related tool calls"""
    
    if name == "create_scene":
        scene_name = arguments["name"]
        scene_path = arguments.get("path")
        root_node_type = arguments.get("root_node_type")
        create_directories = arguments.get("create_directories")
        
        # Validate root node type is specified
        if not root_node_type:
            return [TextContent(
                type="text",
                text=f"Please specify what type of scene you want to create for '{scene_name}':\n"
                     f"- Node2D (for 2D games/sprites)\n"
                     f"- Node3D (for 3D games/meshes)\n"
                     f"- Control (for UI/menus)\n"
                     f"- Node (generic scene, rarely used)\n\n"
                     f"Example: Create a 2D scene called '{scene_name}' with Node2D root"
            )]
        
        # Check directory existence if custom path is provided
        if scene_path and create_directories is None:
            # Extract directory from path
            if "/" in scene_path:
                directory = "/".join(scene_path.split("/")[:-1])
                if directory and directory != "res:":
                    # Check if directory exists by attempting to get current scene info first
                    # This validates connection and then we'll check directory
                    health_check = await godot_client.health_check()
                    if not health_check.get("connected", False):
                        return [TextContent(
                            type="text",
                            text=f"Cannot connect to Godot plugin. Please ensure Godot is running with the plugin enabled."
                        )]
                    
                    return [TextContent(
                        type="text",
                        text=f"Directory '{directory}/' doesn't exist for scene '{scene_name}.tscn'.\n\n"
                             f"Would you like me to:\n"
                             f"- Create the directory and proceed: Create a {root_node_type} scene called '{scene_name}' at '{scene_path}' and create directories\n"
                             f"- Use default location: Create a {root_node_type} scene called '{scene_name}'\n"
                             f"- Cancel: Don't create the scene\n\n"
                             f"Please specify your choice in your next message."
                    )]
        
        result = await godot_client.create_scene(scene_name, scene_path, root_node_type, create_directories)
        
        if result.get("success"):
            directory_msg = ""
            if result.get("directory_created"):
                directory_msg = f" (created directory: {result.get('directory_created')})"
            return [TextContent(
                type="text",
                text=f"Scene '{scene_name}' created successfully at {result.get('scene_path', 'default location')} with {root_node_type} root node{directory_msg}"
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to create scene: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "open_scene":
        scene_path = arguments["path"]
        result = await godot_client.open_scene(scene_path)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Scene opened successfully: {scene_path}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to open scene: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "get_current_scene":
        result = await godot_client.get_current_scene()
        scene_info = result.get("scene")
        
        if scene_info:
            return [TextContent(
                type="text",
                text=f"Current scene: {scene_info['name']}\n"
                     f"Path: {scene_info.get('scene_file_path', 'Not saved')}\n"
                     f"Type: {scene_info['type']}\n"
                     f"Child count: {scene_info['child_count']}"
            )]
        else:
            return [TextContent(
                type="text",
                text="No scene currently open"
            )]
    
    elif name == "add_node":
        node_type = arguments["type"]
        node_name = arguments["name"]
        parent_path = arguments.get("parent_path", "")
        
        result = await godot_client.add_node(node_type, node_name, parent_path)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Node '{node_name}' of type '{node_type}' added successfully"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to add node: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "list_scenes":
        result = await godot_client.list_scenes()
        
        if result.get("scenes") is not None:
            scenes = result.get("scenes", [])
            if not scenes:
                return [TextContent(
                    type="text",
                    text="No scenes found in the project"
                )]
            
            scene_list = "\n".join([
                f"- {scene['name']} ({scene['path']}) in {scene['directory']}"
                for scene in scenes
            ])
            return [TextContent(
                type="text",
                text=f"Found {len(scenes)} scene(s) in the project:\n{scene_list}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to list scenes: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "duplicate_scene":
        source_path = arguments["source_path"]
        target_path = arguments.get("target_path")
        new_name = arguments.get("new_name")
        
        result = await godot_client.duplicate_scene(source_path, target_path, new_name)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Scene duplicated successfully from {result.get('source_path')} to {result.get('target_path')}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to duplicate scene: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "delete_scene":
        scene_path = arguments["path"]
        confirm = arguments["confirm"]
        
        result = await godot_client.delete_scene(scene_path, confirm)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Scene deleted successfully: {scene_path}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to delete scene: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "delete_node":
        node_path = arguments["node_path"]
        confirm = arguments["confirm"]
        
        result = await godot_client.delete_node(node_path, confirm)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Node deleted successfully: {node_path}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to delete node: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "move_node":
        node_path = arguments["node_path"]
        new_parent_path = arguments.get("new_parent_path", "")
        new_index = arguments.get("new_index", -1)
        
        result = await godot_client.move_node(node_path, new_parent_path, new_index)
        
        if result.get("success"):
            move_info = f"Node '{node_path}' moved successfully"
            if result.get("new_parent_path"):
                move_info += f" to parent '{result.get('new_parent_path')}'"
            if result.get("new_index", -1) >= 0:
                move_info += f" at index {result.get('new_index')}"
            return [TextContent(
                type="text",
                text=move_info
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to move node: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "get_node_properties":
        node_path = arguments["node_path"]
        
        result = await godot_client.get_node_properties(node_path)
        
        if result.get("success"):
            properties = result.get("properties", {})
            node_type = result.get("node_type", "Unknown")
            
            if not properties:
                return [TextContent(
                    type="text",
                    text=f"Node '{node_path}' (type: {node_type}) has no accessible properties"
                )]
            
            props_text = "\n".join([f"  {key}: {value}" for key, value in properties.items()])
            return [TextContent(
                type="text",
                text=f"Properties of node '{node_path}' (type: {node_type}):\n{props_text}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to get node properties: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "set_node_properties":
        node_path = arguments["node_path"]
        properties = arguments["properties"]
        
        result = await godot_client.set_node_properties(node_path, properties)
        
        if result.get("success"):
            set_props = result.get("set_properties", [])
            failed_props = result.get("failed_properties", [])
            
            response_text = f"Node '{node_path}' properties updated"
            if set_props:
                response_text += f"\nSet successfully: {', '.join(set_props)}"
            if failed_props:
                response_text += f"\nFailed to set: {', '.join(failed_props)}"
            
            return [TextContent(
                type="text",
                text=response_text
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to set node properties: {result.get('error', 'Unknown error')}"
            )]
    
    else:
        return [TextContent(
            type="text",
            text=f"Unknown scene tool: {name}"
        )]