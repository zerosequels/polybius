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
        ),
        Tool(
            name="list_scripts",
            description="List all script files in the Godot project",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="read_script",
            description="Read the content of an existing script file",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to the script file to read"
                    }
                },
                "required": ["path"]
            }
        ),
        Tool(
            name="modify_script",
            description="Modify the content of an existing script file",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to the script file to modify"
                    },
                    "content": {
                        "type": "string",
                        "description": "New content for the script file"
                    }
                },
                "required": ["path", "content"]
            }
        ),
        Tool(
            name="delete_script",
            description="Delete a script file from the project",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to the script file to delete"
                    },
                    "confirm": {
                        "type": "boolean",
                        "description": "Confirmation flag (must be true to proceed with deletion)"
                    }
                },
                "required": ["path", "confirm"]
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
    
    elif name == "list_scripts":
        result = await godot_client.list_scripts()
        
        if result.get("scripts") is not None:
            scripts = result.get("scripts", [])
            if not scripts:
                return [TextContent(
                    type="text",
                    text="No script files found in the project"
                )]
            
            script_list = "\n".join([
                f"- {script['name']} ({script['path']}) in {script['directory']}"
                for script in scripts
            ])
            return [TextContent(
                type="text",
                text=f"Found {len(scripts)} script(s) in the project:\n{script_list}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to list scripts: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "read_script":
        script_path = arguments["path"]
        
        result = await godot_client.read_script(script_path)
        
        if result.get("success"):
            content = result.get("content", "")
            return [TextContent(
                type="text",
                text=f"Content of script '{script_path}':\n\n```gdscript\n{content}\n```"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to read script: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "modify_script":
        script_path = arguments["path"]
        content = arguments["content"]
        
        result = await godot_client.modify_script(script_path, content)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Script modified successfully: {script_path}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to modify script: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "delete_script":
        script_path = arguments["path"]
        confirm = arguments["confirm"]
        
        result = await godot_client.delete_script(script_path, confirm)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Script deleted successfully: {script_path}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to delete script: {result.get('error', 'Unknown error')}"
            )]
    
    else:
        return [TextContent(
            type="text",
            text=f"Unknown script tool: {name}"
        )]