from mcp.types import Tool, TextContent
from typing import Any, Sequence
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from godot_client import GodotClient

def get_error_tools() -> list[Tool]:
    return [
        Tool(
            name="get_godot_errors",
            description="Get recent errors and warnings from Godot editor",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="clear_godot_errors",
            description="Clear the error log in Godot editor",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        )
    ]

async def handle_error_tool(name: str, arguments: dict, godot_client: GodotClient) -> Sequence[TextContent]:
    """Handle error-related tool calls"""
    
    if name == "get_godot_errors":
        result = await godot_client.get_errors()
        
        if result.get("errors") is not None:
            errors = result.get("errors", [])
            if not errors:
                return [TextContent(
                    type="text",
                    text="No errors currently logged in Godot"
                )]
            
            error_list = []
            for error in errors:
                timestamp = error.get("timestamp", "Unknown time")
                error_type = error.get("type", "UNKNOWN")
                message = error.get("message", "No message")
                source = error.get("source", "")
                
                error_line = f"[{timestamp}] {error_type}: {message}"
                if source:
                    error_line += f" (Source: {source})"
                error_list.append(error_line)
            
            return [TextContent(
                type="text",
                text=f"Found {len(errors)} error(s) in Godot:\n\n" + "\n".join(error_list)
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to get errors: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "clear_godot_errors":
        result = await godot_client.clear_errors()
        
        if result.get("success"):
            cleared_count = result.get("cleared_count", 0)
            return [TextContent(
                type="text",
                text=f"Cleared {cleared_count} error(s) from Godot error log"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to clear errors: {result.get('error', 'Unknown error')}"
            )]
    
    else:
        return [TextContent(
            type="text",
            text=f"Unknown error tool: {name}"
        )]