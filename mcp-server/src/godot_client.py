import httpx
import asyncio
from typing import Dict, Any, Optional
import json

class GodotClient:
    def __init__(self, base_url: str = "http://127.0.0.1:8080"):
        self.base_url = base_url
        self.client = httpx.AsyncClient(timeout=30.0)
    
    async def health_check(self) -> Dict[str, Any]:
        """Check if Godot plugin is running and accessible"""
        try:
            response = await self.client.get(f"{self.base_url}/health")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "connected": False}
    
    async def create_scene(self, name: str, path: Optional[str] = None, root_node_type: Optional[str] = None, create_directories: Optional[bool] = None) -> Dict[str, Any]:
        """Create a new scene in Godot"""
        data = {"name": name}
        if path:
            data["path"] = path
        if root_node_type:
            data["root_node_type"] = root_node_type
        if create_directories is not None:
            data["create_directories"] = create_directories
        
        try:
            response = await self.client.post(f"{self.base_url}/scene/create", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def open_scene(self, path: str) -> Dict[str, Any]:
        """Open an existing scene in Godot"""
        data = {"path": path}
        
        try:
            response = await self.client.post(f"{self.base_url}/scene/open", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def get_current_scene(self) -> Dict[str, Any]:
        """Get information about the currently open scene"""
        try:
            response = await self.client.get(f"{self.base_url}/scene/current")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "scene": None}
    
    async def add_node(self, node_type: str, name: str, parent_path: str = "") -> Dict[str, Any]:
        """Add a new node to the current scene"""
        data = {
            "type": node_type,
            "name": name,
            "parent_path": parent_path
        }
        
        try:
            response = await self.client.post(f"{self.base_url}/node/add", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def create_script(self, path: str, content: Optional[str] = None, attach_to_node: str = "") -> Dict[str, Any]:
        """Create a new GDScript file"""
        data = {"path": path}
        if content:
            data["content"] = content
        if attach_to_node:
            data["attach_to_node"] = attach_to_node
        
        try:
            response = await self.client.post(f"{self.base_url}/script/create", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def list_scenes(self) -> Dict[str, Any]:
        """List all scenes in the Godot project"""
        try:
            response = await self.client.get(f"{self.base_url}/scene/list")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "scenes": []}
    
    async def duplicate_scene(self, source_path: str, target_path: Optional[str] = None, new_name: Optional[str] = None) -> Dict[str, Any]:
        """Duplicate an existing scene"""
        data = {"source_path": source_path}
        if target_path:
            data["target_path"] = target_path
        if new_name:
            data["new_name"] = new_name
        
        try:
            response = await self.client.post(f"{self.base_url}/scene/duplicate", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def delete_scene(self, path: str, confirm: bool = False) -> Dict[str, Any]:
        """Delete a scene file"""
        data = {"path": path, "confirm": confirm}
        
        try:
            response = await self.client.post(f"{self.base_url}/scene/delete", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def delete_node(self, node_path: str, confirm: bool = False) -> Dict[str, Any]:
        """Delete a node from the current scene"""
        data = {"node_path": node_path, "confirm": confirm}
        
        try:
            response = await self.client.post(f"{self.base_url}/node/delete", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def move_node(self, node_path: str, new_parent_path: str = "", new_index: int = -1) -> Dict[str, Any]:
        """Move a node to a new parent or position"""
        data = {"node_path": node_path}
        if new_parent_path:
            data["new_parent_path"] = new_parent_path
        if new_index >= 0:
            data["new_index"] = new_index
        
        try:
            response = await self.client.post(f"{self.base_url}/node/move", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def get_node_properties(self, node_path: str) -> Dict[str, Any]:
        """Get properties of a node"""
        data = {"node_path": node_path}
        
        try:
            response = await self.client.post(f"{self.base_url}/node/properties/get", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def set_node_properties(self, node_path: str, properties: Dict[str, Any]) -> Dict[str, Any]:
        """Set properties of a node"""
        data = {"node_path": node_path, "properties": properties}
        
        try:
            response = await self.client.post(f"{self.base_url}/node/properties/set", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def list_scripts(self) -> Dict[str, Any]:
        """List all script files in the Godot project"""
        try:
            response = await self.client.get(f"{self.base_url}/script/list")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "scripts": []}
    
    async def read_script(self, path: str) -> Dict[str, Any]:
        """Read the content of a script file"""
        data = {"path": path}
        
        try:
            response = await self.client.post(f"{self.base_url}/script/read", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def modify_script(self, path: str, content: str) -> Dict[str, Any]:
        """Modify the content of a script file"""
        data = {"path": path, "content": content}
        
        try:
            response = await self.client.post(f"{self.base_url}/script/modify", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def delete_script(self, path: str, confirm: bool = False) -> Dict[str, Any]:
        """Delete a script file"""
        data = {"path": path, "confirm": confirm}
        
        try:
            response = await self.client.post(f"{self.base_url}/script/delete", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}

    async def get_errors(self) -> Dict[str, Any]:
        """Get error log from Godot plugin"""
        try:
            response = await self.client.get(f"{self.base_url}/errors")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "errors": []}
    
    async def clear_errors(self) -> Dict[str, Any]:
        """Clear error log from Godot plugin"""
        try:
            response = await self.client.post(f"{self.base_url}/errors/clear")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}

    # Asset management methods
    async def import_asset(self, source_path: str, target_path: Optional[str] = None, asset_type: str = "other") -> Dict[str, Any]:
        """Import an external asset into the project"""
        data = {"source_path": source_path, "asset_type": asset_type}
        if target_path:
            data["target_path"] = target_path
        
        try:
            response = await self.client.post(f"{self.base_url}/asset/import", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def list_resources(self, directory: str = "res://", file_types: Optional[list] = None, recursive: bool = True) -> Dict[str, Any]:
        """List project resources with optional filtering"""
        params = {"directory": directory, "recursive": recursive}
        if file_types:
            params["file_types"] = ",".join(file_types)  # Convert list to comma-separated string
        
        try:
            response = await self.client.get(f"{self.base_url}/asset/list", params=params)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "resources": []}
    
    async def organize_assets(self, source_path: str, target_path: str, update_references: bool = True) -> Dict[str, Any]:
        """Move or rename asset files with reference updates"""
        data = {"source_path": source_path, "target_path": target_path, "update_references": update_references}
        
        try:
            response = await self.client.post(f"{self.base_url}/asset/organize", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    # Project management methods
    async def get_project_settings(self, setting_path: Optional[str] = None) -> Dict[str, Any]:
        """Get project settings"""
        params = {}
        if setting_path:
            params["setting_path"] = setting_path
        
        try:
            response = await self.client.get(f"{self.base_url}/project/settings", params=params)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def modify_project_settings(self, setting_path: str, value: Any, create_if_missing: bool = False) -> Dict[str, Any]:
        """Modify project settings"""
        data = {"setting_path": setting_path, "value": value, "create_if_missing": create_if_missing}
        
        try:
            response = await self.client.post(f"{self.base_url}/project/settings", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def export_project(self, preset_name: Optional[str] = None, output_path: Optional[str] = None, debug_mode: bool = False) -> Dict[str, Any]:
        """Export project using specified preset"""
        data = {"debug_mode": debug_mode}
        if preset_name:
            data["preset_name"] = preset_name
        if output_path:
            data["output_path"] = output_path
        
        try:
            response = await self.client.post(f"{self.base_url}/project/export", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    # UI Control methods
    async def set_control_anchors(self, node_path: str, anchor_left: float, anchor_top: float, anchor_right: float, anchor_bottom: float) -> Dict[str, Any]:
        """Set anchor points for a Control node"""
        data = {
            "node_path": node_path,
            "anchor_left": anchor_left,
            "anchor_top": anchor_top, 
            "anchor_right": anchor_right,
            "anchor_bottom": anchor_bottom
        }
        
        try:
            response = await self.client.post(f"{self.base_url}/control/anchors", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def center_control(self, node_path: str, horizontal: bool = True, vertical: bool = True) -> Dict[str, Any]:
        """Center a Control node in its parent"""
        data = {
            "node_path": node_path,
            "horizontal": horizontal,
            "vertical": vertical
        }
        
        try:
            response = await self.client.post(f"{self.base_url}/control/center", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def position_control(self, node_path: str, x: float, y: float, anchor_preset: Optional[str] = None) -> Dict[str, Any]:
        """Set absolute position for a Control node with optional anchor preset"""
        data = {
            "node_path": node_path,
            "x": x,
            "y": y
        }
        if anchor_preset:
            data["anchor_preset"] = anchor_preset
        
        try:
            response = await self.client.post(f"{self.base_url}/control/position", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def fit_control_to_parent(self, node_path: str, margin: float = 0) -> Dict[str, Any]:
        """Make a Control node fill its parent container"""
        data = {
            "node_path": node_path,
            "margin": margin
        }
        
        try:
            response = await self.client.post(f"{self.base_url}/control/fit", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def set_anchor_margins(self, node_path: str, margin_left: float, margin_top: float, margin_right: float, margin_bottom: float) -> Dict[str, Any]:
        """Set margin values from anchor points for a Control node"""
        data = {
            "node_path": node_path,
            "margin_left": margin_left,
            "margin_top": margin_top,
            "margin_right": margin_right,
            "margin_bottom": margin_bottom
        }
        
        try:
            response = await self.client.post(f"{self.base_url}/control/margins", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def configure_size_flags(self, node_path: str, horizontal_flags: list = None, vertical_flags: list = None) -> Dict[str, Any]:
        """Configure how a Control expands and shrinks in containers"""
        data = {
            "node_path": node_path,
            "horizontal_flags": horizontal_flags or [],
            "vertical_flags": vertical_flags or []
        }
        
        try:
            response = await self.client.post(f"{self.base_url}/control/size_flags", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def setup_control_rect(self, node_path: str, x: float, y: float, width: float, height: float, anchor_preset: Optional[str] = None) -> Dict[str, Any]:
        """Set complete position and size for a Control with anchor calculation"""
        data = {
            "node_path": node_path,
            "x": x,
            "y": y,
            "width": width,
            "height": height
        }
        if anchor_preset:
            data["anchor_preset"] = anchor_preset
        
        try:
            response = await self.client.post(f"{self.base_url}/control/rect", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}

    # Smart UI Creation Helper methods
    async def create_centered_ui(self, node_type: str, name: str, parent_path: str = "", width: float = 100, height: float = 100, text: str = "") -> Dict[str, Any]:
        """Create a UI element that is automatically centered in its parent"""
        data = {
            "node_type": node_type,
            "name": name,
            "parent_path": parent_path,
            "width": width,
            "height": height,
            "text": text
        }
        
        try:
            response = await self.client.post(f"{self.base_url}/ui/create_centered", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def create_fullscreen_ui(self, node_type: str, name: str, parent_path: str = "", margin: float = 0) -> Dict[str, Any]:
        """Create a UI element that fills the entire screen or parent container"""
        data = {
            "node_type": node_type,
            "name": name,
            "parent_path": parent_path,
            "margin": margin
        }
        
        try:
            response = await self.client.post(f"{self.base_url}/ui/create_fullscreen", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def setup_ui_container_with_children(self, container_type: str, container_name: str, parent_path: str, positioning: str, children: list, spacing: Optional[float] = None, x: Optional[float] = None, y: Optional[float] = None, width: Optional[float] = None, height: Optional[float] = None) -> Dict[str, Any]:
        """Create a container UI element with properly positioned child elements"""
        data = {
            "container_type": container_type,
            "container_name": container_name,
            "parent_path": parent_path,
            "positioning": positioning,
            "children": children
        }
        if spacing is not None:
            data["spacing"] = spacing
        if x is not None:
            data["x"] = x
        if y is not None:
            data["y"] = y
        if width is not None:
            data["width"] = width
        if height is not None:
            data["height"] = height
        
        try:
            response = await self.client.post(f"{self.base_url}/ui/container_with_children", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def apply_common_ui_patterns(self, pattern: str, parent_path: str = "", name_prefix: str = "", customization: Dict[str, Any] = None) -> Dict[str, Any]:
        """Apply pre-configured UI layouts and patterns"""
        data = {
            "pattern": pattern,
            "parent_path": parent_path,
            "name_prefix": name_prefix or pattern,
            "customization": customization or {}
        }
        
        try:
            response = await self.client.post(f"{self.base_url}/ui/apply_pattern", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}

    # UI Layout Management methods
    async def create_ui_layout(self, container_type: str, name: str, parent_path: str, positioning: str, x: Optional[float] = None, y: Optional[float] = None, width: Optional[float] = None, height: Optional[float] = None, spacing: Optional[float] = None, columns: Optional[int] = None) -> Dict[str, Any]:
        """Create UI containers with automatic positioning"""
        data = {
            "container_type": container_type,
            "name": name,
            "parent_path": parent_path,
            "positioning": positioning
        }
        if x is not None:
            data["x"] = x
        if y is not None:
            data["y"] = y
        if width is not None:
            data["width"] = width
        if height is not None:
            data["height"] = height
        if spacing is not None:
            data["spacing"] = spacing
        if columns is not None:
            data["columns"] = columns
        
        try:
            response = await self.client.post(f"{self.base_url}/layout/create", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def set_anchor_preset(self, node_path: str, preset: str, keep_offsets: bool = False) -> Dict[str, Any]:
        """Apply common anchor presets to Control nodes"""
        data = {
            "node_path": node_path,
            "preset": preset,
            "keep_offsets": keep_offsets
        }
        
        try:
            response = await self.client.post(f"{self.base_url}/layout/anchor_preset", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def align_controls(self, node_paths: list, alignment: str, reference: str = "first") -> Dict[str, Any]:
        """Align multiple UI elements relative to each other"""
        data = {
            "node_paths": node_paths,
            "alignment": alignment,
            "reference": reference
        }
        
        try:
            response = await self.client.post(f"{self.base_url}/layout/align", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}
    
    async def distribute_controls(self, node_paths: list, direction: str, spacing: Optional[float] = None, start_position: Optional[float] = None, end_position: Optional[float] = None) -> Dict[str, Any]:
        """Evenly distribute UI elements horizontally or vertically"""
        data = {
            "node_paths": node_paths,
            "direction": direction
        }
        if spacing is not None:
            data["spacing"] = spacing
        if start_position is not None:
            data["start_position"] = start_position
        if end_position is not None:
            data["end_position"] = end_position
        
        try:
            response = await self.client.post(f"{self.base_url}/layout/distribute", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}

    async def get_node_class_info(self, class_name: str) -> Dict[str, Any]:
        """Get information about a specific Godot node class"""
        data = {"class_name": class_name}
        
        try:
            response = await self.client.post(f"{self.base_url}/node/class_info", json=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}

    async def list_node_classes(self, filter_type: str = "all", search_term: str = "") -> Dict[str, Any]:
        """List available Godot node classes with optional filtering"""
        data = {"filter": filter_type}
        if search_term:
            data["search"] = search_term
        
        try:
            response = await self.client.get(f"{self.base_url}/node/list_classes", params=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e), "success": False}

    async def close(self):
        """Close the HTTP client"""
        await self.client.aclose()