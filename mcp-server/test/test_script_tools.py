import pytest
import asyncio
from unittest.mock import AsyncMock, patch
from mcp.types import TextContent
from src.tools.script_tools import handle_script_tool, get_script_tools
from src.godot_client import GodotClient


class TestScriptTools:
    
    @pytest.fixture
    def mock_client(self):
        """Create a mock GodotClient for testing"""
        return AsyncMock(spec=GodotClient)
    
    @pytest.mark.asyncio
    async def test_create_script_success(self, mock_client):
        """Test successful script creation"""
        mock_client.create_script.return_value = {
            "success": True,
            "script_path": "res://scripts/player.gd"
        }
        
        result = await handle_script_tool("create_script", {
            "path": "res://scripts/player.gd"
        }, mock_client)
        
        mock_client.create_script.assert_called_once_with("res://scripts/player.gd", None, "")
        assert len(result) == 1
        assert isinstance(result[0], TextContent)
        assert "Script created successfully" in result[0].text
        assert "res://scripts/player.gd" in result[0].text
    
    @pytest.mark.asyncio
    async def test_create_script_with_content(self, mock_client):
        """Test script creation with custom content"""
        script_content = "extends Node\n\nfunc _ready():\n\tprint('Hello World')"
        mock_client.create_script.return_value = {
            "success": True,
            "script_path": "res://scripts/hello.gd"
        }
        
        result = await handle_script_tool("create_script", {
            "path": "res://scripts/hello.gd",
            "content": script_content
        }, mock_client)
        
        mock_client.create_script.assert_called_once_with(
            "res://scripts/hello.gd",
            script_content,
            ""
        )
        assert "Script created successfully" in result[0].text
    
    @pytest.mark.asyncio
    async def test_create_script_with_attachment(self, mock_client):
        """Test script creation with node attachment"""
        mock_client.create_script.return_value = {
            "success": True,
            "script_path": "res://scripts/player.gd"
        }
        
        result = await handle_script_tool("create_script", {
            "path": "res://scripts/player.gd",
            "attach_to_node": "Player"
        }, mock_client)
        
        mock_client.create_script.assert_called_once_with(
            "res://scripts/player.gd",
            None,
            "Player"
        )
        assert "Script created successfully" in result[0].text
        assert "attached to node Player" in result[0].text
    
    @pytest.mark.asyncio
    async def test_create_script_with_content_and_attachment(self, mock_client):
        """Test script creation with both content and node attachment"""
        script_content = "extends CharacterBody2D\n\nfunc _physics_process(delta):\n\tmove_and_slide()"
        mock_client.create_script.return_value = {
            "success": True,
            "script_path": "res://scripts/player_controller.gd"
        }
        
        result = await handle_script_tool("create_script", {
            "path": "res://scripts/player_controller.gd",
            "content": script_content,
            "attach_to_node": "PlayerCharacter"
        }, mock_client)
        
        mock_client.create_script.assert_called_once_with(
            "res://scripts/player_controller.gd",
            script_content,
            "PlayerCharacter"
        )
        assert "Script created successfully" in result[0].text
        assert "attached to node PlayerCharacter" in result[0].text
    
    @pytest.mark.asyncio
    async def test_create_script_failure(self, mock_client):
        """Test script creation failure"""
        mock_client.create_script.return_value = {
            "success": False,
            "error": "Invalid script path"
        }
        
        result = await handle_script_tool("create_script", {
            "path": "invalid/path.gd"
        }, mock_client)
        
        assert "Failed to create script" in result[0].text
        assert "Invalid script path" in result[0].text
    
    @pytest.mark.asyncio
    async def test_create_script_permission_error(self, mock_client):
        """Test script creation with permission error"""
        mock_client.create_script.return_value = {
            "success": False,
            "error": "Permission denied"
        }
        
        result = await handle_script_tool("create_script", {
            "path": "res://protected/script.gd"
        }, mock_client)
        
        assert "Failed to create script" in result[0].text
        assert "Permission denied" in result[0].text
    
    @pytest.mark.asyncio
    async def test_create_script_unknown_error(self, mock_client):
        """Test script creation with unknown error"""
        mock_client.create_script.return_value = {
            "success": False
        }
        
        result = await handle_script_tool("create_script", {
            "path": "res://scripts/test.gd"
        }, mock_client)
        
        assert "Failed to create script" in result[0].text
        assert "Unknown error" in result[0].text
    
    @pytest.mark.asyncio
    async def test_unknown_script_tool(self, mock_client):
        """Test handling of unknown script tool"""
        result = await handle_script_tool("unknown_script_tool", {}, mock_client)
        
        assert "Unknown script tool: unknown_script_tool" in result[0].text
    
    def test_script_tools_count(self):
        """Test that expected number of script tools are registered"""
        tools = get_script_tools()
        assert len(tools) == 1  # Only create_script for now
    
    def test_script_tool_names(self):
        """Test that all expected script tools are present"""
        tools = get_script_tools()
        tool_names = [tool.name for tool in tools]
        
        expected_names = ["create_script"]
        for expected_name in expected_names:
            assert expected_name in tool_names, f"Missing tool: {expected_name}"
    
    def test_create_script_tool_schema(self):
        """Test create_script tool has correct schema"""
        tools = get_script_tools()
        create_script_tool = next(tool for tool in tools if tool.name == "create_script")
        
        schema = create_script_tool.inputSchema
        assert schema["type"] == "object"
        assert "path" in schema["properties"]
        assert "content" in schema["properties"]
        assert "attach_to_node" in schema["properties"]
        assert schema["required"] == ["path"]
        assert schema["properties"]["path"]["type"] == "string"
        assert schema["properties"]["content"]["type"] == "string"
        assert schema["properties"]["attach_to_node"]["type"] == "string"
    
    def test_create_script_tool_description(self):
        """Test create_script tool has meaningful description"""
        tools = get_script_tools()
        create_script_tool = next(tool for tool in tools if tool.name == "create_script")
        
        assert create_script_tool.description == "Create a new GDScript file"
        assert len(create_script_tool.description) > 0
    
    @pytest.mark.asyncio
    async def test_create_script_minimal_arguments(self, mock_client):
        """Test script creation with only required arguments"""
        mock_client.create_script.return_value = {
            "success": True,
            "script_path": "res://minimal.gd"
        }
        
        # Test with only the required 'path' argument
        result = await handle_script_tool("create_script", {
            "path": "res://minimal.gd"
        }, mock_client)
        
        # Should pass None for optional content and empty string for attach_to_node
        mock_client.create_script.assert_called_once_with("res://minimal.gd", None, "")
        assert "Script created successfully" in result[0].text
        # Should not mention attachment since no node was specified
        assert "attached to node" not in result[0].text
    
    @pytest.mark.asyncio
    async def test_create_script_empty_attachment(self, mock_client):
        """Test script creation with empty attach_to_node"""
        mock_client.create_script.return_value = {
            "success": True,
            "script_path": "res://empty_attach.gd"
        }
        
        result = await handle_script_tool("create_script", {
            "path": "res://empty_attach.gd",
            "attach_to_node": ""
        }, mock_client)
        
        mock_client.create_script.assert_called_once_with("res://empty_attach.gd", None, "")
        assert "Script created successfully" in result[0].text
        # Should not mention attachment for empty string
        assert "attached to node" not in result[0].text


if __name__ == "__main__":
    pytest.main([__file__])