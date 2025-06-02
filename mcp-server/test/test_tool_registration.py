import pytest
import asyncio
from unittest.mock import AsyncMock, patch
from src.server import GodotMCPServer
from src.tools.scene_tools import get_scene_tools
from src.tools.script_tools import get_script_tools


class TestToolRegistration:
    
    @pytest.fixture
    def server(self):
        """Create a GodotMCPServer instance for testing"""
        return GodotMCPServer()
    
    def test_scene_tools_registration(self):
        """Test that scene tools are properly registered"""
        scene_tools = get_scene_tools()
        tool_names = [tool.name for tool in scene_tools]
        
        expected_tools = ["create_scene", "open_scene", "get_current_scene", "add_node"]
        
        for expected_tool in expected_tools:
            assert expected_tool in tool_names, f"Missing scene tool: {expected_tool}"
        
        assert len(scene_tools) == len(expected_tools), "Unexpected number of scene tools"
    
    def test_script_tools_registration(self):
        """Test that script tools are properly registered"""
        script_tools = get_script_tools()
        tool_names = [tool.name for tool in script_tools]
        
        expected_tools = ["create_script"]
        
        for expected_tool in expected_tools:
            assert expected_tool in tool_names, f"Missing script tool: {expected_tool}"
        
        assert len(script_tools) == len(expected_tools), "Unexpected number of script tools"
    
    @pytest.mark.asyncio
    async def test_all_tools_listed(self, server):
        """Test that all tools are properly listed by the server"""
        from mcp.types import ListToolsRequest
        
        # Get the list_tools handler using the request class as key
        list_tools_handler = server.server.request_handlers.get(ListToolsRequest)
        
        assert list_tools_handler is not None, "list_tools handler not found"
        
        # Create a proper request and call the handler
        request = ListToolsRequest(method="tools/list")
        response = await list_tools_handler(request)
        tools = response.root.tools
        tool_names = [tool.name for tool in tools]
        
        # Check that all expected tools are present
        expected_tools = [
            "create_scene", "open_scene", "get_current_scene", "add_node",  # scene tools
            "create_script",  # script tools
            "godot_health_check"  # health check tool
        ]
        
        for expected_tool in expected_tools:
            assert expected_tool in tool_names, f"Missing tool in server listing: {expected_tool}"
    
    def test_scene_tool_schemas(self):
        """Test that scene tools have proper input schemas"""
        scene_tools = get_scene_tools()
        
        for tool in scene_tools:
            assert hasattr(tool, 'inputSchema'), f"Tool {tool.name} missing input schema"
            assert isinstance(tool.inputSchema, dict), f"Tool {tool.name} schema is not a dict"
            assert tool.inputSchema.get("type") == "object", f"Tool {tool.name} schema type is not object"
            assert "properties" in tool.inputSchema, f"Tool {tool.name} missing properties in schema"
            
            # Check required fields for specific tools
            if tool.name == "create_scene":
                assert "name" in tool.inputSchema["required"], "create_scene missing required 'name' field"
            elif tool.name == "open_scene":
                assert "path" in tool.inputSchema["required"], "open_scene missing required 'path' field"
            elif tool.name == "add_node":
                required_fields = tool.inputSchema["required"]
                assert "type" in required_fields, "add_node missing required 'type' field"
                assert "name" in required_fields, "add_node missing required 'name' field"
    
    def test_script_tool_schemas(self):
        """Test that script tools have proper input schemas"""
        script_tools = get_script_tools()
        
        for tool in script_tools:
            assert hasattr(tool, 'inputSchema'), f"Tool {tool.name} missing input schema"
            assert isinstance(tool.inputSchema, dict), f"Tool {tool.name} schema is not a dict"
            assert tool.inputSchema.get("type") == "object", f"Tool {tool.name} schema type is not object"
            assert "properties" in tool.inputSchema, f"Tool {tool.name} missing properties in schema"
            
            # Check required fields for specific tools
            if tool.name == "create_script":
                assert "path" in tool.inputSchema["required"], "create_script missing required 'path' field"
    
    def test_tool_descriptions(self):
        """Test that all tools have meaningful descriptions"""
        all_tools = get_scene_tools() + get_script_tools()
        
        for tool in all_tools:
            assert hasattr(tool, 'description'), f"Tool {tool.name} missing description"
            assert isinstance(tool.description, str), f"Tool {tool.name} description is not a string"
            assert len(tool.description.strip()) > 0, f"Tool {tool.name} has empty description"
            assert len(tool.description) > 10, f"Tool {tool.name} description too short"
    
    @pytest.mark.asyncio
    async def test_health_check_tool_callable(self, server):
        """Test that the health check tool can be called"""
        from mcp.types import CallToolRequest
        
        # Get the call_tool handler using the request class as key
        call_tool_handler = server.server.request_handlers.get(CallToolRequest)
        
        assert call_tool_handler is not None, "call_tool handler not found"
        
        # Mock the health check to avoid actual HTTP call
        with patch.object(server.godot_client, 'health_check', new_callable=AsyncMock, return_value={"status": "ready"}):
            request = CallToolRequest(method="tools/call", params={"name": "godot_health_check", "arguments": {}})
            response = await call_tool_handler(request)
            result = response.root.content
            
        assert len(result) > 0, "Health check returned empty result"
        assert result[0].type == "text", "Health check result is not text"
        assert "running" in result[0].text.lower(), "Health check result doesn't indicate running status"
    
    @pytest.mark.asyncio  
    async def test_unknown_tool_handling(self, server):
        """Test that unknown tools are handled gracefully"""
        from mcp.types import CallToolRequest
        
        # Get the call_tool handler using the request class as key
        call_tool_handler = server.server.request_handlers.get(CallToolRequest)
        
        assert call_tool_handler is not None, "call_tool handler not found"
        
        request = CallToolRequest(method="tools/call", params={"name": "nonexistent_tool", "arguments": {}})
        response = await call_tool_handler(request)
        result = response.root.content
        
        assert len(result) > 0, "Unknown tool returned empty result"
        assert result[0].type == "text", "Unknown tool result is not text"
        assert "unknown" in result[0].text.lower(), "Unknown tool error message not clear"


if __name__ == "__main__":
    pytest.main([__file__])