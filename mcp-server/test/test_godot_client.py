import pytest
import asyncio
from unittest.mock import AsyncMock, patch
import httpx
from src.godot_client import GodotClient


class TestGodotClient:
    
    @pytest.fixture
    def client(self):
        """Create a GodotClient instance for testing"""
        return GodotClient()
    
    @pytest.mark.asyncio
    async def test_health_check_success(self, client):
        """Test successful health check"""
        from unittest.mock import Mock
        
        mock_response = Mock()
        mock_response.json.return_value = {"status": "ready", "plugin": "claude_mcp"}
        mock_response.raise_for_status = Mock()
        
        with patch.object(client.client, 'get', new_callable=AsyncMock, return_value=mock_response):
            result = await client.health_check()
            
        assert result["status"] == "ready"
        assert result["plugin"] == "claude_mcp"
        assert "error" not in result
    
    @pytest.mark.asyncio
    async def test_health_check_connection_error(self, client):
        """Test health check with connection error"""
        with patch.object(client.client, 'get', new_callable=AsyncMock, side_effect=httpx.ConnectError("Connection failed")):
            result = await client.health_check()
            
        assert result["connected"] is False
        assert "error" in result
        assert "Connection failed" in result["error"]
    
    @pytest.mark.asyncio
    async def test_create_scene_success(self, client):
        """Test successful scene creation"""
        from unittest.mock import Mock
        
        mock_response = Mock()
        mock_response.json.return_value = {"success": True, "scene_path": "res://scenes/TestScene.tscn"}
        mock_response.raise_for_status = Mock()
        
        with patch.object(client.client, 'post', new_callable=AsyncMock, return_value=mock_response):
            result = await client.create_scene("TestScene")
            
        assert result["success"] is True
        assert result["scene_path"] == "res://scenes/TestScene.tscn"
    
    @pytest.mark.asyncio
    async def test_create_scene_with_path(self, client):
        """Test scene creation with custom path"""
        from unittest.mock import Mock
        
        mock_response = Mock()
        mock_response.json.return_value = {"success": True, "scene_path": "res://custom/MyScene.tscn"}
        mock_response.raise_for_status = Mock()
        
        with patch.object(client.client, 'post', new_callable=AsyncMock, return_value=mock_response) as mock_post:
            result = await client.create_scene("MyScene", "res://custom/MyScene.tscn")
            
        mock_post.assert_called_once_with(
            "http://127.0.0.1:8080/scene/create",
            json={"name": "MyScene", "path": "res://custom/MyScene.tscn"}
        )
        assert result["success"] is True
    
    @pytest.mark.asyncio
    async def test_open_scene_success(self, client):
        """Test successful scene opening"""
        from unittest.mock import Mock
        
        mock_response = Mock()
        mock_response.json.return_value = {"success": True}
        mock_response.raise_for_status = Mock()
        
        with patch.object(client.client, 'post', new_callable=AsyncMock, return_value=mock_response):
            result = await client.open_scene("res://scenes/TestScene.tscn")
            
        assert result["success"] is True
    
    @pytest.mark.asyncio
    async def test_get_current_scene_success(self, client):
        """Test getting current scene info"""
        from unittest.mock import Mock
        
        mock_response = Mock()
        mock_response.json.return_value = {
            "scene": {
                "name": "TestScene",
                "scene_file_path": "res://scenes/TestScene.tscn",
                "type": "Node2D",
                "child_count": 3
            }
        }
        mock_response.raise_for_status = Mock()
        
        with patch.object(client.client, 'get', new_callable=AsyncMock, return_value=mock_response):
            result = await client.get_current_scene()
            
        assert result["scene"]["name"] == "TestScene"
        assert result["scene"]["child_count"] == 3
    
    @pytest.mark.asyncio
    async def test_add_node_success(self, client):
        """Test successful node addition"""
        from unittest.mock import Mock
        
        mock_response = Mock()
        mock_response.json.return_value = {"success": True, "node_path": "TestLabel"}
        mock_response.raise_for_status = Mock()
        
        with patch.object(client.client, 'post', new_callable=AsyncMock, return_value=mock_response):
            result = await client.add_node("Label", "TestLabel", "UI")
            
        assert result["success"] is True
        assert result["node_path"] == "TestLabel"
    
    @pytest.mark.asyncio
    async def test_create_script_success(self, client):
        """Test successful script creation"""
        from unittest.mock import Mock
        
        mock_response = Mock()
        mock_response.json.return_value = {"success": True, "script_path": "res://scripts/test.gd"}
        mock_response.raise_for_status = Mock()
        
        script_content = "extends Node\n\nfunc _ready():\n\tprint('Hello')"
        
        with patch.object(client.client, 'post', new_callable=AsyncMock, return_value=mock_response) as mock_post:
            result = await client.create_script("res://scripts/test.gd", script_content, "TestNode")
            
        mock_post.assert_called_once_with(
            "http://127.0.0.1:8080/script/create",
            json={
                "path": "res://scripts/test.gd",
                "content": script_content,
                "attach_to_node": "TestNode"
            }
        )
        assert result["success"] is True
    
    @pytest.mark.asyncio
    async def test_http_error_handling(self, client):
        """Test HTTP error handling"""
        with patch.object(client.client, 'get', new_callable=AsyncMock, side_effect=httpx.HTTPStatusError("404 Not Found", request=None, response=None)):
            result = await client.health_check()
            
        assert result["connected"] is False
        assert "error" in result
    
    @pytest.mark.asyncio
    async def test_close_client(self, client):
        """Test closing the HTTP client"""
        with patch.object(client.client, 'aclose') as mock_close:
            await client.close()
            mock_close.assert_called_once()


if __name__ == "__main__":
    pytest.main([__file__])