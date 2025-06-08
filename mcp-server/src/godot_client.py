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

    async def close(self):
        """Close the HTTP client"""
        await self.client.aclose()