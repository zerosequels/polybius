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
    
    else:
        return [TextContent(
            type="text",
            text=f"Unknown scene tool: {name}"
        )]