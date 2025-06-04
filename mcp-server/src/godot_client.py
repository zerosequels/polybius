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
    
    async def create_scene(self, name: str, path: Optional[str] = None, root_node_type: Optional[str] = None) -> Dict[str, Any]:
        """Create a new scene in Godot"""
        data = {"name": name}
        if path:
            data["path"] = path
        if root_node_type:
            data["root_node_type"] = root_node_type
        
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
    
    async def close(self):
        """Close the HTTP client"""
        await self.client.aclose()