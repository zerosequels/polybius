from mcp.types import Tool, TextContent
import json
from typing import Any, Sequence
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from godot_client import GodotClient

# Theme management tools
def get_theme_tools() -> list[Tool]:
    return [
        Tool(
            name="create_theme",
            description="Create a new Theme resource in Godot with configurable properties",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "Name of the new theme"
                    },
                    "path": {
                        "type": "string",
                        "description": "Optional file path for the theme resource (defaults to res://themes/{name}.tres)"
                    },
                    "base_theme": {
                        "type": "string",
                        "description": "Optional base theme to inherit from (default_theme, editor_theme, or path to existing theme)"
                    },
                    "properties": {
                        "type": "object",
                        "description": "Initial theme properties to set",
                        "properties": {
                            "default_font_size": {"type": "integer", "description": "Default font size for all controls"},
                            "colors": {
                                "type": "object",
                                "description": "Color properties",
                                "additionalProperties": {"type": "string"}
                            },
                            "fonts": {
                                "type": "object", 
                                "description": "Font properties",
                                "additionalProperties": {"type": "string"}
                            },
                            "font_sizes": {
                                "type": "object",
                                "description": "Font size properties", 
                                "additionalProperties": {"type": "integer"}
                            },
                            "icons": {
                                "type": "object",
                                "description": "Icon properties",
                                "additionalProperties": {"type": "string"}
                            },
                            "styles": {
                                "type": "object",
                                "description": "StyleBox properties",
                                "additionalProperties": {"type": "string"}
                            }
                        }
                    }
                },
                "required": ["name"]
            }
        ),
        Tool(
            name="apply_theme",
            description="Apply a theme to Control nodes or entire scenes",
            inputSchema={
                "type": "object",
                "properties": {
                    "theme_path": {
                        "type": "string",
                        "description": "Path to the theme resource to apply"
                    },
                    "target": {
                        "type": "string",
                        "description": "Target to apply theme to: 'scene' for entire scene, or node path for specific Control node",
                        "default": "scene"
                    },
                    "node_path": {
                        "type": "string",
                        "description": "Specific node path if target is not 'scene'"
                    },
                    "recursive": {
                        "type": "boolean",
                        "description": "Whether to apply theme recursively to all child Control nodes",
                        "default": true
                    }
                },
                "required": ["theme_path"]
            }
        ),
        Tool(
            name="modify_theme_properties",
            description="Edit specific properties of an existing theme resource",
            inputSchema={
                "type": "object",
                "properties": {
                    "theme_path": {
                        "type": "string",
                        "description": "Path to the theme resource to modify"
                    },
                    "properties": {
                        "type": "object",
                        "description": "Theme properties to modify",
                        "properties": {
                            "default_font_size": {"type": "integer", "description": "Default font size"},
                            "colors": {
                                "type": "object",
                                "description": "Color properties to set/modify",
                                "additionalProperties": {"type": "string"}
                            },
                            "fonts": {
                                "type": "object",
                                "description": "Font properties to set/modify", 
                                "additionalProperties": {"type": "string"}
                            },
                            "font_sizes": {
                                "type": "object",
                                "description": "Font size properties to set/modify",
                                "additionalProperties": {"type": "integer"}
                            },
                            "icons": {
                                "type": "object",
                                "description": "Icon properties to set/modify",
                                "additionalProperties": {"type": "string"}
                            },
                            "styles": {
                                "type": "object",
                                "description": "StyleBox properties to set/modify",
                                "additionalProperties": {"type": "string"}
                            }
                        }
                    },
                    "remove_properties": {
                        "type": "array",
                        "description": "Array of property names to remove from theme",
                        "items": {"type": "string"}
                    }
                },
                "required": ["theme_path", "properties"]
            }
        ),
        Tool(
            name="import_theme",
            description="Import external theme files into the Godot project",
            inputSchema={
                "type": "object",
                "properties": {
                    "source_path": {
                        "type": "string",
                        "description": "Path to the external theme file to import"
                    },
                    "target_path": {
                        "type": "string",
                        "description": "Optional target path in project (defaults to res://themes/)"
                    },
                    "theme_name": {
                        "type": "string",
                        "description": "Name for the imported theme (defaults to source filename)"
                    },
                    "overwrite": {
                        "type": "boolean",
                        "description": "Whether to overwrite existing theme with same name",
                        "default": false
                    }
                },
                "required": ["source_path"]
            }
        ),
        Tool(
            name="export_theme",
            description="Export theme resources for external use or sharing",
            inputSchema={
                "type": "object",
                "properties": {
                    "theme_path": {
                        "type": "string",
                        "description": "Path to the theme resource to export"
                    },
                    "export_path": {
                        "type": "string",
                        "description": "Path where to export the theme file"
                    },
                    "format": {
                        "type": "string",
                        "description": "Export format",
                        "enum": ["tres", "res"],
                        "default": "tres"
                    },
                    "include_dependencies": {
                        "type": "boolean",
                        "description": "Whether to include dependent resources (fonts, textures)",
                        "default": true
                    }
                },
                "required": ["theme_path", "export_path"]
            }
        ),
        Tool(
            name="list_themes",
            description="List all theme resources in the project",
            inputSchema={
                "type": "object",
                "properties": {
                    "directory": {
                        "type": "string",
                        "description": "Directory to search for themes (defaults to entire project)",
                        "default": "res://"
                    },
                    "recursive": {
                        "type": "boolean",
                        "description": "Whether to search recursively in subdirectories",
                        "default": true
                    }
                }
            }
        ),
        Tool(
            name="get_theme_properties",
            description="Retrieve properties and settings from an existing theme resource",
            inputSchema={
                "type": "object",
                "properties": {
                    "theme_path": {
                        "type": "string",
                        "description": "Path to the theme resource to inspect"
                    },
                    "property_type": {
                        "type": "string",
                        "description": "Specific property type to retrieve (colors, fonts, font_sizes, icons, styles, all)",
                        "enum": ["colors", "fonts", "font_sizes", "icons", "styles", "all"],
                        "default": "all"
                    }
                },
                "required": ["theme_path"]
            }
        )
    ]

async def handle_create_theme(arguments: dict) -> Sequence[TextContent]:
    """Create a new Theme resource with specified properties"""
    try:
        client = GodotClient()
        response = await client.post('/theme/create', arguments)
        
        if response.get('success'):
            return [TextContent(
                type="text", 
                text=f"Successfully created theme '{arguments['name']}' at '{response.get('path', 'unknown path')}'"
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to create theme: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error creating theme: {str(e)}")]

async def handle_apply_theme(arguments: dict) -> Sequence[TextContent]:
    """Apply a theme to Control nodes or scenes"""
    try:
        client = GodotClient()
        response = await client.post('/theme/apply', arguments)
        
        if response.get('success'):
            target_info = response.get('applied_to', 'unknown target')
            return [TextContent(
                type="text", 
                text=f"Successfully applied theme to {target_info}. {response.get('nodes_affected', 0)} nodes affected."
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to apply theme: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error applying theme: {str(e)}")]

async def handle_modify_theme_properties(arguments: dict) -> Sequence[TextContent]:
    """Modify properties of an existing theme"""
    try:
        client = GodotClient()
        response = await client.post('/theme/modify', arguments)
        
        if response.get('success'):
            modified_count = response.get('properties_modified', 0)
            removed_count = response.get('properties_removed', 0)
            return [TextContent(
                type="text", 
                text=f"Successfully modified theme: {modified_count} properties modified, {removed_count} properties removed"
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to modify theme: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error modifying theme: {str(e)}")]

async def handle_import_theme(arguments: dict) -> Sequence[TextContent]:
    """Import external theme files"""
    try:
        client = GodotClient()
        response = await client.post('/theme/import', arguments)
        
        if response.get('success'):
            return [TextContent(
                type="text", 
                text=f"Successfully imported theme to '{response.get('imported_path', 'unknown path')}'"
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to import theme: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error importing theme: {str(e)}")]

async def handle_export_theme(arguments: dict) -> Sequence[TextContent]:
    """Export theme resources for external use"""
    try:
        client = GodotClient()
        response = await client.post('/theme/export', arguments)
        
        if response.get('success'):
            return [TextContent(
                type="text", 
                text=f"Successfully exported theme to '{response.get('exported_path', 'unknown path')}'"
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to export theme: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error exporting theme: {str(e)}")]

async def handle_list_themes(arguments: dict) -> Sequence[TextContent]:
    """List all theme resources in the project"""
    try:
        client = GodotClient()
        response = await client.get('/theme/list', arguments)
        
        if response.get('success'):
            themes = response.get('themes', [])
            if not themes:
                return [TextContent(type="text", text="No theme resources found in the project")]
            
            theme_list = "\n".join([
                f"- {theme['name']} ({theme['path']}) - {theme.get('size', 'unknown size')}"
                for theme in themes
            ])
            return [TextContent(
                type="text", 
                text=f"Found {len(themes)} theme resource(s):\n{theme_list}"
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to list themes: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error listing themes: {str(e)}")]

async def handle_get_theme_properties(arguments: dict) -> Sequence[TextContent]:
    """Get properties from an existing theme"""
    try:
        client = GodotClient()
        response = await client.post('/theme/properties/get', arguments)
        
        if response.get('success'):
            properties = response.get('properties', {})
            property_type = arguments.get('property_type', 'all')
            
            if not properties:
                return [TextContent(type="text", text=f"No {property_type} properties found in theme")]
            
            # Format the properties for display
            formatted_props = []
            if property_type == 'all':
                for prop_type, props in properties.items():
                    if props:
                        formatted_props.append(f"\n{prop_type.upper()}:")
                        for key, value in props.items():
                            formatted_props.append(f"  {key}: {value}")
            else:
                props = properties.get(property_type, {})
                for key, value in props.items():
                    formatted_props.append(f"{key}: {value}")
            
            result_text = f"Theme properties ({property_type}):" + "\n".join(formatted_props)
            return [TextContent(type="text", text=result_text)]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to get theme properties: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error getting theme properties: {str(e)}")]

# Main theme tool handler
async def handle_theme_tool(name: str, arguments: dict, client: GodotClient = None) -> Sequence[TextContent]:
    """Handle theme tool calls"""
    if name == "create_theme":
        return await handle_create_theme(arguments)
    elif name == "apply_theme":
        return await handle_apply_theme(arguments)
    elif name == "modify_theme_properties":
        return await handle_modify_theme_properties(arguments)
    elif name == "import_theme":
        return await handle_import_theme(arguments)
    elif name == "export_theme":
        return await handle_export_theme(arguments)
    elif name == "list_themes":
        return await handle_list_themes(arguments)
    elif name == "get_theme_properties":
        return await handle_get_theme_properties(arguments)
    else:
        return [TextContent(type="text", text=f"Unknown theme tool: {name}")]