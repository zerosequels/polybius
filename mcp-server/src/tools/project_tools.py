from mcp.types import Tool, TextContent
import json
from typing import Any, Sequence
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from godot_client import GodotClient

# Project management tools
def get_project_tools() -> list[Tool]:
    return [
        Tool(
            name="get_project_settings",
            description="Read project configuration from project.godot file",
            inputSchema={
                "type": "object",
                "properties": {
                    "setting_path": {
                        "type": "string",
                        "description": "Specific setting path to retrieve (e.g., 'application/config/name'). If not provided, returns all settings."
                    }
                }
            }
        ),
        Tool(
            name="modify_project_settings",
            description="Update project settings in project.godot file",
            inputSchema={
                "type": "object",
                "properties": {
                    "setting_path": {
                        "type": "string",
                        "description": "Setting path to modify (e.g., 'application/config/name')"
                    },
                    "value": {
                        "description": "New value for the setting (can be string, number, boolean, or object)"
                    },
                    "create_if_missing": {
                        "type": "boolean",
                        "description": "Whether to create the setting if it doesn't exist (defaults to false)"
                    }
                },
                "required": ["setting_path", "value"]
            }
        ),
        Tool(
            name="export_project",
            description="Build/export the Godot project to target platforms",
            inputSchema={
                "type": "object",
                "properties": {
                    "preset_name": {
                        "type": "string",
                        "description": "Name of the export preset to use (if not provided, lists available presets)"
                    },
                    "output_path": {
                        "type": "string",
                        "description": "Output path for the exported project (optional, uses preset default if not provided)"
                    },
                    "debug_mode": {
                        "type": "boolean",
                        "description": "Whether to export in debug mode (defaults to false)"
                    }
                }
            }
        )
    ]

async def handle_project_tool(name: str, arguments: dict, godot_client: GodotClient) -> Sequence[TextContent]:
    """Handle project-related tool calls"""
    
    if name == "get_project_settings":
        setting_path = arguments.get("setting_path")
        
        result = await godot_client.get_project_settings(setting_path)
        
        if result.get("success"):
            settings = result.get("settings")
            if setting_path:
                return [TextContent(
                    type="text",
                    text=f"Setting '{setting_path}': {settings}"
                )]
            else:
                if not settings:
                    return [TextContent(
                        type="text",
                        text="No project settings found"
                    )]
                
                settings_text = "\n".join([f"  {key}: {value}" for key, value in settings.items()])
                return [TextContent(
                    type="text",
                    text=f"Project settings:\n{settings_text}"
                )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to get project settings: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "modify_project_settings":
        setting_path = arguments["setting_path"]
        value = arguments["value"]
        create_if_missing = arguments.get("create_if_missing", False)
        
        result = await godot_client.modify_project_settings(setting_path, value, create_if_missing)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Project setting '{setting_path}' updated to: {value}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to modify project setting: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "export_project":
        preset_name = arguments.get("preset_name")
        output_path = arguments.get("output_path")
        debug_mode = arguments.get("debug_mode", False)
        
        result = await godot_client.export_project(preset_name, output_path, debug_mode)
        
        if result.get("success"):
            if not preset_name and result.get("available_presets"):
                presets = result.get("available_presets", [])
                preset_list = "\n".join([f"- {preset}" for preset in presets])
                return [TextContent(
                    type="text",
                    text=f"Available export presets:\n{preset_list}\n\nUse the preset_name parameter to export with a specific preset."
                )]
            else:
                return [TextContent(
                    type="text",
                    text=f"Project exported successfully using preset '{preset_name}' to {result.get('output_path', 'default location')}"
                )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to export project: {result.get('error', 'Unknown error')}"
            )]
    
    else:
        return [TextContent(
            type="text",
            text=f"Unknown project tool: {name}"
        )]