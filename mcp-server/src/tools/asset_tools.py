from mcp.types import Tool, TextContent
import json
from typing import Any, Sequence
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from godot_client import GodotClient

# Asset management tools
def get_asset_tools() -> list[Tool]:
    return [
        Tool(
            name="import_asset",
            description="Import external files (images, audio, models) into the Godot project",
            inputSchema={
                "type": "object",
                "properties": {
                    "source_path": {
                        "type": "string",
                        "description": "Path to the external file to import"
                    },
                    "target_path": {
                        "type": "string",
                        "description": "Target path in project (res:// format, optional - will auto-generate if not provided)"
                    },
                    "asset_type": {
                        "type": "string",
                        "description": "Type of asset being imported",
                        "enum": ["image", "audio", "model", "texture", "font", "other"]
                    }
                },
                "required": ["source_path", "asset_type"]
            }
        ),
        Tool(
            name="list_resources", 
            description="List all project resources with optional filtering",
            inputSchema={
                "type": "object",
                "properties": {
                    "directory": {
                        "type": "string",
                        "description": "Directory to search in (defaults to res://)"
                    },
                    "file_types": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "File extensions to filter by (e.g., ['.png', '.jpg', '.ogg'])"
                    },
                    "recursive": {
                        "type": "boolean",
                        "description": "Search subdirectories recursively (defaults to true)"
                    }
                }
            }
        ),
        Tool(
            name="organize_assets",
            description="Move or rename resource files and update references",
            inputSchema={
                "type": "object",
                "properties": {
                    "source_path": {
                        "type": "string",
                        "description": "Current path of the asset to move/rename"
                    },
                    "target_path": {
                        "type": "string",
                        "description": "New path for the asset"
                    },
                    "update_references": {
                        "type": "boolean",
                        "description": "Whether to update references in scenes and scripts (defaults to true)"
                    }
                },
                "required": ["source_path", "target_path"]
            }
        )
    ]

async def handle_asset_tool(name: str, arguments: dict, godot_client: GodotClient) -> Sequence[TextContent]:
    """Handle asset-related tool calls"""
    
    if name == "import_asset":
        source_path = arguments["source_path"]
        target_path = arguments.get("target_path")
        asset_type = arguments["asset_type"]
        
        result = await godot_client.import_asset(source_path, target_path, asset_type)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Asset imported successfully from {source_path} to {result.get('target_path')}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to import asset: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "list_resources":
        directory = arguments.get("directory", "res://")
        file_types = arguments.get("file_types")
        recursive = arguments.get("recursive", True)
        
        result = await godot_client.list_resources(directory, file_types, recursive)
        
        if result.get("resources") is not None:
            resources = result.get("resources", [])
            if not resources:
                return [TextContent(
                    type="text",
                    text=f"No resources found in {directory}"
                )]
            
            resource_list = "\n".join([
                f"- {resource['name']} ({resource['path']}) - {resource.get('size', 'unknown size')} - {resource.get('type', 'unknown type')}"
                for resource in resources
            ])
            return [TextContent(
                type="text",
                text=f"Found {len(resources)} resource(s) in {directory}:\n{resource_list}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to list resources: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "organize_assets":
        source_path = arguments["source_path"]
        target_path = arguments["target_path"]
        update_references = arguments.get("update_references", True)
        
        result = await godot_client.organize_assets(source_path, target_path, update_references)
        
        if result.get("success"):
            response_text = f"Asset moved successfully from {source_path} to {target_path}"
            if result.get("references_updated"):
                response_text += f"\nUpdated {result.get('references_updated')} reference(s)"
            return [TextContent(
                type="text",
                text=response_text
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to organize asset: {result.get('error', 'Unknown error')}"
            )]
    
    else:
        return [TextContent(
            type="text",
            text=f"Unknown asset tool: {name}"
        )]