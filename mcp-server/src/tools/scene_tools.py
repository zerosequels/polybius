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
        ),
        Tool(
            name="set_control_anchors",
            description="Set anchor points for a Control node (anchor_left, anchor_top, anchor_right, anchor_bottom)",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the Control node"
                    },
                    "anchor_left": {
                        "type": "number",
                        "description": "Left anchor (0.0 to 1.0)",
                        "minimum": 0.0,
                        "maximum": 1.0
                    },
                    "anchor_top": {
                        "type": "number", 
                        "description": "Top anchor (0.0 to 1.0)",
                        "minimum": 0.0,
                        "maximum": 1.0
                    },
                    "anchor_right": {
                        "type": "number",
                        "description": "Right anchor (0.0 to 1.0)",
                        "minimum": 0.0,
                        "maximum": 1.0
                    },
                    "anchor_bottom": {
                        "type": "number",
                        "description": "Bottom anchor (0.0 to 1.0)",
                        "minimum": 0.0,
                        "maximum": 1.0
                    }
                },
                "required": ["node_path", "anchor_left", "anchor_top", "anchor_right", "anchor_bottom"]
            }
        ),
        Tool(
            name="center_control",
            description="Center a Control node in its parent container (both horizontally and vertically)",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the Control node to center"
                    },
                    "horizontal": {
                        "type": "boolean",
                        "description": "Whether to center horizontally (default: true)"
                    },
                    "vertical": {
                        "type": "boolean", 
                        "description": "Whether to center vertically (default: true)"
                    }
                },
                "required": ["node_path"]
            }
        ),
        Tool(
            name="position_control",
            description="Set absolute position for a Control node with proper anchor handling",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the Control node"
                    },
                    "x": {
                        "type": "number",
                        "description": "X position in pixels"
                    },
                    "y": {
                        "type": "number",
                        "description": "Y position in pixels"
                    },
                    "anchor_preset": {
                        "type": "string",
                        "description": "Optional anchor preset to apply before positioning",
                        "enum": ["top_left", "top_right", "bottom_left", "bottom_right", "center_left", "center_top", "center_right", "center_bottom", "center", "full_rect"]
                    }
                },
                "required": ["node_path", "x", "y"]
            }
        ),
        Tool(
            name="fit_control_to_parent",
            description="Make a Control node fill its parent container completely",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the Control node"
                    },
                    "margin": {
                        "type": "number",
                        "description": "Optional margin from parent edges in pixels (default: 0)"
                    }
                },
                "required": ["node_path"]
            }
        ),
        Tool(
            name="set_anchor_margins",
            description="Set margin values from anchor points for precise Control positioning",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the Control node"
                    },
                    "margin_left": {
                        "type": "number",
                        "description": "Left margin in pixels"
                    },
                    "margin_top": {
                        "type": "number",
                        "description": "Top margin in pixels"
                    },
                    "margin_right": {
                        "type": "number",
                        "description": "Right margin in pixels"
                    },
                    "margin_bottom": {
                        "type": "number",
                        "description": "Bottom margin in pixels"
                    }
                },
                "required": ["node_path", "margin_left", "margin_top", "margin_right", "margin_bottom"]
            }
        ),
        Tool(
            name="configure_size_flags",
            description="Configure how a Control expands and shrinks in containers",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the Control node"
                    },
                    "horizontal_flags": {
                        "type": "array",
                        "items": {
                            "type": "string",
                            "enum": ["fill", "expand", "shrink_center", "shrink_end"]
                        },
                        "description": "Horizontal size flags (fill, expand, shrink_center, shrink_end)"
                    },
                    "vertical_flags": {
                        "type": "array",
                        "items": {
                            "type": "string",
                            "enum": ["fill", "expand", "shrink_center", "shrink_end"]
                        },
                        "description": "Vertical size flags (fill, expand, shrink_center, shrink_end)"
                    }
                },
                "required": ["node_path"]
            }
        ),
        Tool(
            name="setup_control_rect",
            description="Set complete position and size for a Control with proper anchor calculation",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the Control node"
                    },
                    "x": {
                        "type": "number",
                        "description": "X position in pixels"
                    },
                    "y": {
                        "type": "number",
                        "description": "Y position in pixels"
                    },
                    "width": {
                        "type": "number",
                        "description": "Width in pixels"
                    },
                    "height": {
                        "type": "number",
                        "description": "Height in pixels"
                    },
                    "anchor_preset": {
                        "type": "string",
                        "description": "Optional anchor preset to apply",
                        "enum": ["top_left", "top_right", "bottom_left", "bottom_right", "center_left", "center_top", "center_right", "center_bottom", "center", "full_rect"]
                    }
                },
                "required": ["node_path", "x", "y", "width", "height"]
            }
        ),
        Tool(
            name="create_centered_ui",
            description="Create a UI element (Control node) that is automatically centered in its parent",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_type": {
                        "type": "string",
                        "description": "Type of Control node to create",
                        "enum": ["Control", "Label", "Button", "Panel", "PanelContainer", "VBoxContainer", "HBoxContainer"]
                    },
                    "name": {
                        "type": "string",
                        "description": "Name for the new UI element"
                    },
                    "parent_path": {
                        "type": "string",
                        "description": "Path to parent node (empty for scene root)"
                    },
                    "width": {
                        "type": "number",
                        "description": "Width of the UI element in pixels (optional, defaults to 100)"
                    },
                    "height": {
                        "type": "number",
                        "description": "Height of the UI element in pixels (optional, defaults to 100)"
                    },
                    "text": {
                        "type": "string",
                        "description": "Text content (for Label/Button nodes)"
                    }
                },
                "required": ["node_type", "name"]
            }
        ),
        Tool(
            name="create_fullscreen_ui",
            description="Create a UI element that properly fills the entire screen or its parent container",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_type": {
                        "type": "string",
                        "description": "Type of Control node to create",
                        "enum": ["Control", "Panel", "PanelContainer", "VBoxContainer", "HBoxContainer", "ColorRect"]
                    },
                    "name": {
                        "type": "string",
                        "description": "Name for the new UI element"
                    },
                    "parent_path": {
                        "type": "string",
                        "description": "Path to parent node (empty for scene root)"
                    },
                    "margin": {
                        "type": "number",
                        "description": "Margin from edges in pixels (optional, defaults to 0)"
                    }
                },
                "required": ["node_type", "name"]
            }
        ),
        Tool(
            name="setup_ui_container_with_children",
            description="Create a container UI element with properly positioned child elements",
            inputSchema={
                "type": "object",
                "properties": {
                    "container_type": {
                        "type": "string",
                        "description": "Type of container to create",
                        "enum": ["VBoxContainer", "HBoxContainer", "GridContainer", "PanelContainer", "MarginContainer"]
                    },
                    "container_name": {
                        "type": "string",
                        "description": "Name for the container"
                    },
                    "parent_path": {
                        "type": "string",
                        "description": "Path to parent node (empty for scene root)"
                    },
                    "positioning": {
                        "type": "string",
                        "description": "How to position the container",
                        "enum": ["centered", "fullscreen", "top_left", "custom"]
                    },
                    "children": {
                        "type": "array",
                        "description": "Array of child elements to create",
                        "items": {
                            "type": "object",
                            "properties": {
                                "type": {
                                    "type": "string",
                                    "description": "Type of child node"
                                },
                                "name": {
                                    "type": "string",
                                    "description": "Name of child node"
                                },
                                "text": {
                                    "type": "string",
                                    "description": "Text content for text nodes"
                                },
                                "width": {
                                    "type": "number",
                                    "description": "Custom width for the child (optional)"
                                },
                                "height": {
                                    "type": "number",
                                    "description": "Custom height for the child (optional)"
                                }
                            },
                            "required": ["type", "name"]
                        }
                    },
                    "spacing": {
                        "type": "number",
                        "description": "Spacing between child elements (for VBox/HBox containers)"
                    },
                    "x": {
                        "type": "number",
                        "description": "X position for custom positioning"
                    },
                    "y": {
                        "type": "number",
                        "description": "Y position for custom positioning"
                    },
                    "width": {
                        "type": "number",
                        "description": "Container width for custom positioning"
                    },
                    "height": {
                        "type": "number",
                        "description": "Container height for custom positioning"
                    }
                },
                "required": ["container_type", "container_name", "positioning", "children"]
            }
        ),
        Tool(
            name="apply_common_ui_patterns",
            description="Apply pre-configured UI layouts and patterns (main menu, HUD, dialog, etc.)",
            inputSchema={
                "type": "object",
                "properties": {
                    "pattern": {
                        "type": "string",
                        "description": "UI pattern to apply",
                        "enum": ["main_menu", "pause_menu", "hud", "dialog", "settings_panel", "inventory_grid", "health_bar", "button_row"]
                    },
                    "parent_path": {
                        "type": "string",
                        "description": "Path to parent node (empty for scene root)"
                    },
                    "name_prefix": {
                        "type": "string",
                        "description": "Prefix for generated node names (optional, defaults to pattern name)"
                    },
                    "customization": {
                        "type": "object",
                        "description": "Pattern-specific customization options",
                        "properties": {
                            "title": {
                                "type": "string",
                                "description": "Title text for menus/dialogs"
                            },
                            "buttons": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "Button text for menus (e.g., ['Start Game', 'Settings', 'Quit'])"
                            },
                            "grid_columns": {
                                "type": "number",
                                "description": "Number of columns for grid patterns"
                            },
                            "max_value": {
                                "type": "number",
                                "description": "Maximum value for progress bars/health bars"
                            }
                        }
                    }
                },
                "required": ["pattern"]
            }
        ),
        Tool(
            name="create_ui_layout",
            description="Create UI containers (VBoxContainer, HBoxContainer, GridContainer, etc.) with automatic positioning",
            inputSchema={
                "type": "object",
                "properties": {
                    "container_type": {
                        "type": "string",
                        "description": "Type of container to create",
                        "enum": ["VBoxContainer", "HBoxContainer", "GridContainer", "TabContainer", "HSplitContainer", "VSplitContainer", "ScrollContainer", "PanelContainer", "MarginContainer"]
                    },
                    "name": {
                        "type": "string",
                        "description": "Name for the container"
                    },
                    "parent_path": {
                        "type": "string",
                        "description": "Path to parent node (empty for scene root)"
                    },
                    "positioning": {
                        "type": "string",
                        "description": "How to position the container",
                        "enum": ["centered", "fullscreen", "top_left", "top_right", "bottom_left", "bottom_right", "custom"]
                    },
                    "x": {
                        "type": "number",
                        "description": "X position for custom positioning"
                    },
                    "y": {
                        "type": "number",
                        "description": "Y position for custom positioning"
                    },
                    "width": {
                        "type": "number",
                        "description": "Container width (optional, defaults to auto-size)"
                    },
                    "height": {
                        "type": "number",
                        "description": "Container height (optional, defaults to auto-size)"
                    },
                    "spacing": {
                        "type": "number",
                        "description": "Spacing between elements (for VBox/HBox containers)"
                    },
                    "columns": {
                        "type": "number",
                        "description": "Number of columns (for GridContainer)"
                    }
                },
                "required": ["container_type", "name", "positioning"]
            }
        ),
        Tool(
            name="set_anchor_preset",
            description="Apply common anchor presets to Control nodes (center, full rect, corners, etc.)",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the Control node"
                    },
                    "preset": {
                        "type": "string",
                        "description": "Anchor preset to apply",
                        "enum": ["top_left", "top_right", "bottom_left", "bottom_right", "center_left", "center_top", "center_right", "center_bottom", "center", "left_wide", "top_wide", "right_wide", "bottom_wide", "vcenter_wide", "hcenter_wide", "full_rect"]
                    },
                    "keep_offsets": {
                        "type": "boolean",
                        "description": "Whether to keep current offset values (default: false)"
                    }
                },
                "required": ["node_path", "preset"]
            }
        ),
        Tool(
            name="align_controls",
            description="Align multiple UI elements relative to each other (left, center, right, top, bottom)",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_paths": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Paths to the Control nodes to align",
                        "minItems": 2
                    },
                    "alignment": {
                        "type": "string",
                        "description": "How to align the controls",
                        "enum": ["left", "center", "right", "top", "middle", "bottom", "center_horizontal", "center_vertical"]
                    },
                    "reference": {
                        "type": "string",
                        "description": "Reference for alignment: 'first' (use first node), 'last' (use last node), 'parent' (align to parent bounds)",
                        "enum": ["first", "last", "parent"]
                    }
                },
                "required": ["node_paths", "alignment"]
            }
        ),
        Tool(
            name="distribute_controls",
            description="Evenly distribute UI elements horizontally or vertically with specified spacing",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_paths": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Paths to the Control nodes to distribute",
                        "minItems": 3
                    },
                    "direction": {
                        "type": "string",
                        "description": "Direction to distribute elements",
                        "enum": ["horizontal", "vertical"]
                    },
                    "spacing": {
                        "type": "number",
                        "description": "Spacing between elements in pixels (optional, defaults to even distribution)"
                    },
                    "start_position": {
                        "type": "number",
                        "description": "Starting position for distribution (optional, uses current bounds)"
                    },
                    "end_position": {
                        "type": "number",
                        "description": "Ending position for distribution (optional, uses current bounds)"
                    }
                },
                "required": ["node_paths", "direction"]
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
    
    elif name == "set_control_anchors":
        node_path = arguments["node_path"]
        anchor_left = arguments["anchor_left"]
        anchor_top = arguments["anchor_top"]
        anchor_right = arguments["anchor_right"]
        anchor_bottom = arguments["anchor_bottom"]
        
        result = await godot_client.set_control_anchors(node_path, anchor_left, anchor_top, anchor_right, anchor_bottom)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Control anchors set for node '{node_path}': left={anchor_left}, top={anchor_top}, right={anchor_right}, bottom={anchor_bottom}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to set control anchors: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "center_control":
        node_path = arguments["node_path"]
        horizontal = arguments.get("horizontal", True)
        vertical = arguments.get("vertical", True)
        
        result = await godot_client.center_control(node_path, horizontal, vertical)
        
        if result.get("success"):
            center_direction = []
            if horizontal:
                center_direction.append("horizontally")
            if vertical:
                center_direction.append("vertically")
            direction_text = " and ".join(center_direction)
            
            return [TextContent(
                type="text",
                text=f"Control node '{node_path}' centered {direction_text}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to center control: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "position_control":
        node_path = arguments["node_path"]
        x = arguments["x"]
        y = arguments["y"]
        anchor_preset = arguments.get("anchor_preset")
        
        result = await godot_client.position_control(node_path, x, y, anchor_preset)
        
        if result.get("success"):
            response_text = f"Control node '{node_path}' positioned at ({x}, {y})"
            if anchor_preset:
                response_text += f" with {anchor_preset} anchor preset"
            
            return [TextContent(
                type="text",
                text=response_text
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to position control: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "fit_control_to_parent":
        node_path = arguments["node_path"]
        margin = arguments.get("margin", 0)
        
        result = await godot_client.fit_control_to_parent(node_path, margin)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Control node '{node_path}' fitted to parent with {margin}px margin"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to fit control to parent: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "set_anchor_margins":
        node_path = arguments["node_path"]
        margin_left = arguments["margin_left"]
        margin_top = arguments["margin_top"]
        margin_right = arguments["margin_right"]
        margin_bottom = arguments["margin_bottom"]
        
        result = await godot_client.set_anchor_margins(node_path, margin_left, margin_top, margin_right, margin_bottom)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Anchor margins set for node '{node_path}': left={margin_left}, top={margin_top}, right={margin_right}, bottom={margin_bottom}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to set anchor margins: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "configure_size_flags":
        node_path = arguments["node_path"]
        horizontal_flags = arguments.get("horizontal_flags", [])
        vertical_flags = arguments.get("vertical_flags", [])
        
        result = await godot_client.configure_size_flags(node_path, horizontal_flags, vertical_flags)
        
        if result.get("success"):
            response_text = f"Size flags configured for node '{node_path}'"
            if horizontal_flags:
                response_text += f" - Horizontal: {', '.join(horizontal_flags)}"
            if vertical_flags:
                response_text += f" - Vertical: {', '.join(vertical_flags)}"
            
            return [TextContent(
                type="text",
                text=response_text
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to configure size flags: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "setup_control_rect":
        node_path = arguments["node_path"]
        x = arguments["x"]
        y = arguments["y"]
        width = arguments["width"]
        height = arguments["height"]
        anchor_preset = arguments.get("anchor_preset")
        
        result = await godot_client.setup_control_rect(node_path, x, y, width, height, anchor_preset)
        
        if result.get("success"):
            response_text = f"Control rect set for node '{node_path}': position=({x}, {y}), size=({width}, {height})"
            if anchor_preset:
                response_text += f" with {anchor_preset} anchor preset"
            
            return [TextContent(
                type="text",
                text=response_text
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to setup control rect: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "create_centered_ui":
        node_type = arguments["node_type"]
        name = arguments["name"]
        parent_path = arguments.get("parent_path", "")
        width = arguments.get("width", 100)
        height = arguments.get("height", 100)
        text = arguments.get("text", "")
        
        result = await godot_client.create_centered_ui(node_type, name, parent_path, width, height, text)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Centered UI element '{name}' of type '{node_type}' created successfully with size {width}x{height}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to create centered UI: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "create_fullscreen_ui":
        node_type = arguments["node_type"]
        name = arguments["name"]
        parent_path = arguments.get("parent_path", "")
        margin = arguments.get("margin", 0)
        
        result = await godot_client.create_fullscreen_ui(node_type, name, parent_path, margin)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Fullscreen UI element '{name}' of type '{node_type}' created successfully with {margin}px margin"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to create fullscreen UI: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "setup_ui_container_with_children":
        container_type = arguments["container_type"]
        container_name = arguments["container_name"]
        parent_path = arguments.get("parent_path", "")
        positioning = arguments["positioning"]
        children = arguments["children"]
        spacing = arguments.get("spacing")
        x = arguments.get("x")
        y = arguments.get("y")
        width = arguments.get("width")
        height = arguments.get("height")
        
        result = await godot_client.setup_ui_container_with_children(
            container_type, container_name, parent_path, positioning, children, 
            spacing, x, y, width, height
        )
        
        if result.get("success"):
            created_children = result.get("created_children", [])
            return [TextContent(
                type="text",
                text=f"Container '{container_name}' created with {len(created_children)} children: {', '.join(created_children)}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to create UI container: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "apply_common_ui_patterns":
        pattern = arguments["pattern"]
        parent_path = arguments.get("parent_path", "")
        name_prefix = arguments.get("name_prefix", pattern)
        customization = arguments.get("customization", {})
        
        result = await godot_client.apply_common_ui_patterns(pattern, parent_path, name_prefix, customization)
        
        if result.get("success"):
            created_nodes = result.get("created_nodes", [])
            return [TextContent(
                type="text",
                text=f"UI pattern '{pattern}' applied successfully. Created nodes: {', '.join(created_nodes)}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to apply UI pattern: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "create_ui_layout":
        container_type = arguments["container_type"]
        name = arguments["name"]
        parent_path = arguments.get("parent_path", "")
        positioning = arguments["positioning"]
        x = arguments.get("x")
        y = arguments.get("y")
        width = arguments.get("width")
        height = arguments.get("height")
        spacing = arguments.get("spacing")
        columns = arguments.get("columns")
        
        result = await godot_client.create_ui_layout(
            container_type, name, parent_path, positioning, x, y, width, height, spacing, columns
        )
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"UI layout container '{name}' of type '{container_type}' created successfully with {positioning} positioning"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to create UI layout: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "set_anchor_preset":
        node_path = arguments["node_path"]
        preset = arguments["preset"]
        keep_offsets = arguments.get("keep_offsets", False)
        
        result = await godot_client.set_anchor_preset(node_path, preset, keep_offsets)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Anchor preset '{preset}' applied to node '{node_path}'"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to set anchor preset: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "align_controls":
        node_paths = arguments["node_paths"]
        alignment = arguments["alignment"]
        reference = arguments.get("reference", "first")
        
        result = await godot_client.align_controls(node_paths, alignment, reference)
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Aligned {len(node_paths)} controls with '{alignment}' alignment using '{reference}' reference"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to align controls: {result.get('error', 'Unknown error')}"
            )]
    
    elif name == "distribute_controls":
        node_paths = arguments["node_paths"]
        direction = arguments["direction"]
        spacing = arguments.get("spacing")
        start_position = arguments.get("start_position")
        end_position = arguments.get("end_position")
        
        result = await godot_client.distribute_controls(
            node_paths, direction, spacing, start_position, end_position
        )
        
        if result.get("success"):
            return [TextContent(
                type="text",
                text=f"Distributed {len(node_paths)} controls {direction}ly with spacing of {result.get('actual_spacing', 'auto')}"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"Failed to distribute controls: {result.get('error', 'Unknown error')}"
            )]
    
    else:
        return [TextContent(
            type="text",
            text=f"Unknown scene tool: {name}"
        )]