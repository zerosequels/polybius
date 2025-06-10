from mcp.types import Tool, TextContent
import json
from typing import Any, Sequence
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from godot_client import GodotClient

# UI Animation & Interaction tools
def get_animation_tools() -> list[Tool]:
    return [
        Tool(
            name="create_ui_animation",
            description="Set up Tween nodes for UI animations with configurable properties and targets",
            inputSchema={
                "type": "object",
                "properties": {
                    "target_node_path": {
                        "type": "string",
                        "description": "Path to the UI node to animate"
                    },
                    "animation_name": {
                        "type": "string",
                        "description": "Name for the animation/Tween node",
                        "default": "UIAnimation"
                    },
                    "animation_type": {
                        "type": "string",
                        "description": "Type of animation to create",
                        "enum": ["fade_in", "fade_out", "slide_in", "slide_out", "scale_up", "scale_down", "rotate", "color_change", "custom"],
                        "default": "fade_in"
                    },
                    "duration": {
                        "type": "number",
                        "description": "Animation duration in seconds",
                        "default": 1.0
                    },
                    "easing": {
                        "type": "string", 
                        "description": "Easing function for animation",
                        "enum": ["linear", "ease_in", "ease_out", "ease_in_out", "bounce", "elastic"],
                        "default": "ease_out"
                    },
                    "direction": {
                        "type": "string",
                        "description": "Direction for slide animations",
                        "enum": ["left", "right", "up", "down"],
                        "default": "left"
                    },
                    "custom_properties": {
                        "type": "object",
                        "description": "Custom animation properties for advanced animations",
                        "properties": {
                            "from_value": {"description": "Starting value for custom animation"},
                            "to_value": {"description": "Ending value for custom animation"},
                            "property_name": {"type": "string", "description": "Property to animate"}
                        }
                    },
                    "auto_start": {
                        "type": "boolean",
                        "description": "Whether to automatically start the animation",
                        "default": false
                    },
                    "loop": {
                        "type": "boolean", 
                        "description": "Whether the animation should loop",
                        "default": false
                    }
                },
                "required": ["target_node_path"]
            }
        ),
        Tool(
            name="configure_ui_signals",
            description="Connect UI signals to script methods for interactive behavior",
            inputSchema={
                "type": "object",
                "properties": {
                    "node_path": {
                        "type": "string",
                        "description": "Path to the UI node to configure signals for"
                    },
                    "signals": {
                        "type": "array",
                        "description": "Array of signal configurations",
                        "items": {
                            "type": "object",
                            "properties": {
                                "signal_name": {
                                    "type": "string",
                                    "description": "Name of the signal to connect (e.g., 'pressed', 'text_changed', 'toggled')"
                                },
                                "target_node_path": {
                                    "type": "string", 
                                    "description": "Path to node that will receive the signal (defaults to node with script)"
                                },
                                "method_name": {
                                    "type": "string",
                                    "description": "Name of the method to call when signal is emitted"
                                },
                                "create_method": {
                                    "type": "boolean",
                                    "description": "Whether to create the method if it doesn't exist",
                                    "default": true
                                },
                                "method_parameters": {
                                    "type": "array",
                                    "description": "Parameters for the created method",
                                    "items": {"type": "string"}
                                },
                                "method_body": {
                                    "type": "string",
                                    "description": "Body content for created method"
                                }
                            },
                            "required": ["signal_name", "method_name"]
                        }
                    },
                    "script_path": {
                        "type": "string",
                        "description": "Path to script file to attach/modify (creates if doesn't exist)"
                    },
                    "auto_attach_script": {
                        "type": "boolean",
                        "description": "Whether to automatically attach script to target node",
                        "default": true
                    }
                },
                "required": ["node_path", "signals"]
            }
        ),
        Tool(
            name="setup_focus_navigation",
            description="Configure tab order and focus behavior for UI elements",
            inputSchema={
                "type": "object",
                "properties": {
                    "focus_chain": {
                        "type": "array",
                        "description": "Array of node paths in focus order",
                        "items": {"type": "string"}
                    },
                    "focus_mode": {
                        "type": "string",
                        "description": "Focus behavior for all nodes in chain",
                        "enum": ["none", "click", "all"],
                        "default": "all"
                    },
                    "wrap_around": {
                        "type": "boolean",
                        "description": "Whether focus wraps from last to first element",
                        "default": true
                    },
                    "focus_visual_settings": {
                        "type": "object",
                        "description": "Visual settings for focused elements",
                        "properties": {
                            "enable_focus_outline": {"type": "boolean", "default": true},
                            "outline_color": {"type": "string", "description": "Color for focus outline (hex format)"},
                            "outline_thickness": {"type": "number", "description": "Thickness of focus outline in pixels"}
                        }
                    },
                    "keyboard_navigation": {
                        "type": "object",
                        "description": "Keyboard navigation settings",
                        "properties": {
                            "enable_arrow_keys": {"type": "boolean", "default": true},
                            "enable_wasd": {"type": "boolean", "default": false},
                            "custom_key_bindings": {
                                "type": "object",
                                "description": "Custom key bindings for navigation",
                                "additionalProperties": {"type": "string"}
                            }
                        }
                    },
                    "initial_focus_node": {
                        "type": "string",
                        "description": "Node path that should have initial focus"
                    }
                },
                "required": ["focus_chain"]
            }
        ),
        Tool(
            name="start_ui_animation",
            description="Start or control existing UI animations",
            inputSchema={
                "type": "object",
                "properties": {
                    "animation_node_path": {
                        "type": "string",
                        "description": "Path to the Tween node to control"
                    },
                    "action": {
                        "type": "string",
                        "description": "Action to perform on animation",
                        "enum": ["start", "stop", "pause", "resume", "reset"],
                        "default": "start"
                    },
                    "reverse": {
                        "type": "boolean",
                        "description": "Whether to play animation in reverse",
                        "default": false
                    },
                    "speed_scale": {
                        "type": "number",
                        "description": "Speed multiplier for animation playback",
                        "default": 1.0
                    }
                },
                "required": ["animation_node_path"]
            }
        ),
        Tool(
            name="create_ui_transition",
            description="Create smooth transitions between UI states or scenes",
            inputSchema={
                "type": "object",
                "properties": {
                    "transition_name": {
                        "type": "string",
                        "description": "Name for the transition setup"
                    },
                    "from_state": {
                        "type": "object",
                        "description": "Starting state configuration",
                        "properties": {
                            "node_path": {"type": "string"},
                            "properties": {"type": "object", "description": "Initial property values"}
                        },
                        "required": ["node_path"]
                    },
                    "to_state": {
                        "type": "object", 
                        "description": "Target state configuration",
                        "properties": {
                            "node_path": {"type": "string"},
                            "properties": {"type": "object", "description": "Target property values"}
                        },
                        "required": ["node_path"]
                    },
                    "transition_type": {
                        "type": "string",
                        "description": "Type of transition",
                        "enum": ["fade", "slide", "scale", "morph", "cross_fade"],
                        "default": "fade"
                    },
                    "duration": {
                        "type": "number",
                        "description": "Transition duration in seconds",
                        "default": 0.5
                    },
                    "easing": {
                        "type": "string",
                        "description": "Easing function for transition",
                        "enum": ["linear", "ease_in", "ease_out", "ease_in_out", "bounce", "elastic"],
                        "default": "ease_in_out"
                    },
                    "auto_execute": {
                        "type": "boolean",
                        "description": "Whether to execute transition immediately",
                        "default": false
                    }
                },
                "required": ["transition_name", "from_state", "to_state"]
            }
        )
    ]

async def handle_create_ui_animation(arguments: dict) -> Sequence[TextContent]:
    """Create Tween nodes for UI animations"""
    try:
        client = GodotClient()
        response = await client.post('/animation/create', arguments)
        
        if response.get('success'):
            return [TextContent(
                type="text", 
                text=f"Successfully created UI animation '{arguments.get('animation_name', 'UIAnimation')}' for node '{arguments['target_node_path']}'"
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to create UI animation: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error creating UI animation: {str(e)}")]

async def handle_configure_ui_signals(arguments: dict) -> Sequence[TextContent]:
    """Connect UI signals to script methods"""
    try:
        client = GodotClient()
        response = await client.post('/animation/signals', arguments)
        
        if response.get('success'):
            signals_connected = response.get('signals_connected', 0)
            methods_created = response.get('methods_created', 0)
            return [TextContent(
                type="text", 
                text=f"Successfully configured UI signals: {signals_connected} signals connected, {methods_created} methods created"
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to configure UI signals: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error configuring UI signals: {str(e)}")]

async def handle_setup_focus_navigation(arguments: dict) -> Sequence[TextContent]:
    """Configure tab order and focus behavior"""
    try:
        client = GodotClient()
        response = await client.post('/animation/focus', arguments)
        
        if response.get('success'):
            nodes_configured = response.get('nodes_configured', 0)
            return [TextContent(
                type="text", 
                text=f"Successfully set up focus navigation: {nodes_configured} nodes configured in focus chain"
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to setup focus navigation: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error setting up focus navigation: {str(e)}")]

async def handle_start_ui_animation(arguments: dict) -> Sequence[TextContent]:
    """Start or control existing UI animations"""
    try:
        client = GodotClient()
        response = await client.post('/animation/control', arguments)
        
        if response.get('success'):
            action = arguments.get('action', 'start')
            return [TextContent(
                type="text", 
                text=f"Successfully {action}ed animation '{arguments['animation_node_path']}'"
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to control animation: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error controlling animation: {str(e)}")]

async def handle_create_ui_transition(arguments: dict) -> Sequence[TextContent]:
    """Create smooth transitions between UI states"""
    try:
        client = GodotClient()
        response = await client.post('/animation/transition', arguments)
        
        if response.get('success'):
            return [TextContent(
                type="text", 
                text=f"Successfully created UI transition '{arguments['transition_name']}' between states"
            )]
        else:
            return [TextContent(
                type="text", 
                text=f"Failed to create UI transition: {response.get('error', 'Unknown error')}"
            )]
    except Exception as e:
        return [TextContent(type="text", text=f"Error creating UI transition: {str(e)}")]

# Main animation tool handler
async def handle_animation_tool(name: str, arguments: dict, client: GodotClient = None) -> Sequence[TextContent]:
    """Handle animation tool calls"""
    if name == "create_ui_animation":
        return await handle_create_ui_animation(arguments)
    elif name == "configure_ui_signals":
        return await handle_configure_ui_signals(arguments)
    elif name == "setup_focus_navigation":
        return await handle_setup_focus_navigation(arguments)
    elif name == "start_ui_animation":
        return await handle_start_ui_animation(arguments)
    elif name == "create_ui_transition":
        return await handle_create_ui_transition(arguments)
    else:
        return [TextContent(type="text", text=f"Unknown animation tool: {name}")]