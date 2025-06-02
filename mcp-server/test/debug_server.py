#!/usr/bin/env python3
"""
Debug script to inspect MCP server structure and handler responses
"""

import sys
import os
import asyncio

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from src.server import GodotMCPServer
from unittest.mock import AsyncMock, patch

async def debug_server():
    """Debug the MCP server structure and handler responses"""
    print("=== Debugging MCP Server Structure ===")
    
    server = GodotMCPServer()
    
    print(f"Server type: {type(server.server)}")
    print(f"Server attributes: {[attr for attr in dir(server.server) if not attr.startswith('__')]}")
    
    if hasattr(server.server, 'request_handlers'):
        print(f"Request handlers: {server.server.request_handlers}")
        print(f"Request handler keys: {list(server.server.request_handlers.keys())}")
    else:
        print("No request_handlers attribute found")
    
    # Test list_tools handler
    print("\n=== Testing list_tools handler ===")
    from mcp.types import ListToolsRequest
    
    list_tools_handler = server.server.request_handlers.get(ListToolsRequest)
    if list_tools_handler:
        try:
            request = ListToolsRequest(method="tools/list")
            response = await list_tools_handler(request)
            print(f"List tools response type: {type(response)}")
            print(f"List tools response attributes: {[attr for attr in dir(response) if not attr.startswith('__')]}")
            print(f"List tools response: {response}")
            
            # Try to access response data different ways
            if hasattr(response, 'tools'):
                print(f"Response.tools: {response.tools}")
            if hasattr(response, 'result'):
                print(f"Response.result: {response.result}")
            if hasattr(response, 'data'):
                print(f"Response.data: {response.data}")
                
        except Exception as e:
            print(f"Error calling list_tools handler: {e}")
    
    # Test call_tool handler
    print("\n=== Testing call_tool handler ===")
    from mcp.types import CallToolRequest
    
    call_tool_handler = server.server.request_handlers.get(CallToolRequest)
    if call_tool_handler:
        try:
            with patch.object(server.godot_client, 'health_check', new_callable=AsyncMock, return_value={"status": "ready"}):
                request = CallToolRequest(method="tools/call", params={"name": "godot_health_check", "arguments": {}})
                response = await call_tool_handler(request)
                print(f"Call tool response type: {type(response)}")
                print(f"Call tool response attributes: {[attr for attr in dir(response) if not attr.startswith('__')]}")
                print(f"Call tool response: {response}")
                
                # Try to access response data different ways
                if hasattr(response, 'content'):
                    print(f"Response.content: {response.content}")
                if hasattr(response, 'result'):
                    print(f"Response.result: {response.result}")
                if hasattr(response, 'data'):
                    print(f"Response.data: {response.data}")
                    
        except Exception as e:
            print(f"Error calling call_tool handler: {e}")
    
    await server.godot_client.close()

if __name__ == "__main__":
    asyncio.run(debug_server())