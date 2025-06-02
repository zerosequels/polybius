import pytest
import asyncio
from unittest.mock import AsyncMock, patch
from mcp.types import TextContent
from src.tools.scene_tools import handle_scene_tool, get_scene_tools
from src.godot_client import GodotClient


class TestSceneTools:
    
    @pytest.fixture
    def mock_client(self):
        """Create a mock GodotClient for testing"""
        return AsyncMock(spec=GodotClient)
    
    @pytest.mark.asyncio
    async def test_create_scene_success(self, mock_client):
        """Test successful scene creation"""
        mock_client.create_scene.return_value = {
            "success": True,
            "scene_path": "res://scenes/TestScene.tscn"
        }
        
        result = await handle_scene_tool("create_scene", {"name": "TestScene"}, mock_client)
        
        mock_client.create_scene.assert_called_once_with("TestScene", None)
        assert len(result) == 1
        assert isinstance(result[0], TextContent)
        assert "TestScene" in result[0].text
        assert "created successfully" in result[0].text
    
    @pytest.mark.asyncio
    async def test_create_scene_with_path(self, mock_client):
        """Test scene creation with custom path"""
        mock_client.create_scene.return_value = {
            "success": True,
            "scene_path": "res://custom/MyScene.tscn"
        }
        
        result = await handle_scene_tool("create_scene", {
            "name": "MyScene",
            "path": "res://custom/MyScene.tscn"
        }, mock_client)
        
        mock_client.create_scene.assert_called_once_with("MyScene", "res://custom/MyScene.tscn")
        assert "MyScene" in result[0].text
        assert "created successfully" in result[0].text
    
    @pytest.mark.asyncio
    async def test_create_scene_failure(self, mock_client):
        """Test scene creation failure"""
        mock_client.create_scene.return_value = {
            "success": False,
            "error": "Invalid scene name"
        }
        
        result = await handle_scene_tool("create_scene", {"name": "Invalid@Name"}, mock_client)
        
        assert len(result) == 1
        assert "Failed to create scene" in result[0].text
        assert "Invalid scene name" in result[0].text
    
    @pytest.mark.asyncio
    async def test_open_scene_success(self, mock_client):
        """Test successful scene opening"""
        mock_client.open_scene.return_value = {"success": True}
        
        result = await handle_scene_tool("open_scene", {
            "path": "res://scenes/TestScene.tscn"
        }, mock_client)
        
        mock_client.open_scene.assert_called_once_with("res://scenes/TestScene.tscn")
        assert "Scene opened successfully" in result[0].text
        assert "TestScene.tscn" in result[0].text
    
    @pytest.mark.asyncio
    async def test_open_scene_failure(self, mock_client):
        """Test scene opening failure"""
        mock_client.open_scene.return_value = {
            "success": False,
            "error": "Scene file not found"
        }
        
        result = await handle_scene_tool("open_scene", {
            "path": "res://nonexistent.tscn"
        }, mock_client)
        
        assert "Failed to open scene" in result[0].text
        assert "Scene file not found" in result[0].text
    
    @pytest.mark.asyncio
    async def test_get_current_scene_with_scene(self, mock_client):
        """Test getting current scene info when scene is open"""
        mock_client.get_current_scene.return_value = {
            "scene": {
                "name": "TestScene",
                "scene_file_path": "res://scenes/TestScene.tscn",
                "type": "Node2D",
                "child_count": 5
            }
        }
        
        result = await handle_scene_tool("get_current_scene", {}, mock_client)
        
        assert "Current scene: TestScene" in result[0].text
        assert "Path: res://scenes/TestScene.tscn" in result[0].text
        assert "Type: Node2D" in result[0].text
        assert "Child count: 5" in result[0].text
    
    @pytest.mark.asyncio
    async def test_get_current_scene_no_scene(self, mock_client):
        """Test getting current scene info when no scene is open"""
        mock_client.get_current_scene.return_value = {"scene": None}
        
        result = await handle_scene_tool("get_current_scene", {}, mock_client)
        
        assert "No scene currently open" in result[0].text
    
    @pytest.mark.asyncio
    async def test_get_current_scene_not_saved(self, mock_client):
        """Test getting current scene info for unsaved scene"""
        mock_client.get_current_scene.return_value = {
            "scene": {
                "name": "UnsavedScene",
                "type": "Node",
                "child_count": 0
            }
        }
        
        result = await handle_scene_tool("get_current_scene", {}, mock_client)
        
        assert "Current scene: UnsavedScene" in result[0].text
        assert "Path: Not saved" in result[0].text
    
    @pytest.mark.asyncio
    async def test_add_node_success(self, mock_client):
        """Test successful node addition"""
        mock_client.add_node.return_value = {"success": True}
        
        result = await handle_scene_tool("add_node", {
            "type": "Label",
            "name": "TestLabel",
            "parent_path": "UI"
        }, mock_client)
        
        mock_client.add_node.assert_called_once_with("Label", "TestLabel", "UI")
        assert "Node 'TestLabel' of type 'Label' added successfully" in result[0].text
    
    @pytest.mark.asyncio
    async def test_add_node_no_parent(self, mock_client):
        """Test node addition without parent path"""
        mock_client.add_node.return_value = {"success": True}
        
        result = await handle_scene_tool("add_node", {
            "type": "Node2D",
            "name": "Player"
        }, mock_client)
        
        mock_client.add_node.assert_called_once_with("Node2D", "Player", "")
        assert "Node 'Player' of type 'Node2D' added successfully" in result[0].text
    
    @pytest.mark.asyncio
    async def test_add_node_failure(self, mock_client):
        """Test node addition failure"""
        mock_client.add_node.return_value = {
            "success": False,
            "error": "Invalid node type"
        }
        
        result = await handle_scene_tool("add_node", {
            "type": "InvalidType",
            "name": "TestNode"
        }, mock_client)
        
        assert "Failed to add node" in result[0].text
        assert "Invalid node type" in result[0].text
    
    @pytest.mark.asyncio
    async def test_unknown_tool(self, mock_client):
        """Test handling of unknown scene tool"""
        result = await handle_scene_tool("unknown_tool", {}, mock_client)
        
        assert "Unknown scene tool: unknown_tool" in result[0].text
    
    def test_scene_tools_count(self):
        """Test that expected number of scene tools are registered"""
        tools = get_scene_tools()
        assert len(tools) == 4  # create_scene, open_scene, get_current_scene, add_node
    
    def test_scene_tool_names(self):
        """Test that all expected scene tools are present"""
        tools = get_scene_tools()
        tool_names = [tool.name for tool in tools]
        
        expected_names = ["create_scene", "open_scene", "get_current_scene", "add_node"]
        for expected_name in expected_names:
            assert expected_name in tool_names, f"Missing tool: {expected_name}"
    
    def test_create_scene_tool_schema(self):
        """Test create_scene tool has correct schema"""
        tools = get_scene_tools()
        create_scene_tool = next(tool for tool in tools if tool.name == "create_scene")
        
        schema = create_scene_tool.inputSchema
        assert schema["type"] == "object"
        assert "name" in schema["properties"]
        assert "path" in schema["properties"]
        assert schema["required"] == ["name"]
        assert schema["properties"]["name"]["type"] == "string"
        assert schema["properties"]["path"]["type"] == "string"
    
    def test_add_node_tool_schema(self):
        """Test add_node tool has correct schema"""
        tools = get_scene_tools()
        add_node_tool = next(tool for tool in tools if tool.name == "add_node")
        
        schema = add_node_tool.inputSchema
        assert schema["type"] == "object"
        assert "type" in schema["properties"]
        assert "name" in schema["properties"]
        assert "parent_path" in schema["properties"]
        assert set(schema["required"]) == {"type", "name"}


if __name__ == "__main__":
    pytest.main([__file__])