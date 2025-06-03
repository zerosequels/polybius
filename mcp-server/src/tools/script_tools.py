from mcp.types import Tool, TextContent
from typing import Any, Sequence
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from godot_client import GodotClient

def get_script_tools() -> list[Tool]:
    return [
        Tool(
            name="create_script",
            description="Create a new GDScript file",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path where the script should be created (e.g., res://scripts/player.gd)"
                    },
                    "content": {
                        "type": "string",
                        "description": "Optional script content (defaults to basic template)"
                    },
                    "attach_to_node": {
                        "type": "string",
                        "description": "Optional node path to attach the script to"
                    }
                },
                "required": ["path"]
            }
        )
    ]

async def handle_script_tool(name: str, arguments: dict, godot_client: GodotClient) -> Sequence[TextContent]:
    """Handle script-related tool calls"""
    
    if name == "create_script":
        script_path = arguments["path"]
        content = arguments.get("content")
        attach_to_node = arguments.get("attach_to_node", "")
        
        result = await godot_client.create_script(script_path, content, attach_to_node)
        
        if result.get("success"):
            message = f"Script created successfully at {script_path}"
            if attach_to_node:
                message += f" and attached to node {attach_to_node}"
            return [TextContent(type="text", text=message)]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to create script: {result.get('error', 'Unknown error')}"
            )]
    
    else:
        return [TextContent(
            type="text",
            text=f"Unknown script tool: {name}"
        )]