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
            description="Create a new scene in Godot",
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
        result = await godot_client.create_scene(scene_name, scene_path)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Scene '{scene_name}' created successfully at {result.get('scene_path', 'default location')}"
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