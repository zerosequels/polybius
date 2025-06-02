#!/usr/bin/env python3
"""
Test utilities for debugging MCP server test issues
"""

import asyncio
import httpx
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from src.godot_client import GodotClient


async def test_httpx_response_behavior():
    """Test how httpx responses behave - sync vs async json()"""
    print("=== Testing HTTPX Response Behavior ===")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get('https://httpbin.org/json')
            print(f'Response type: {type(response)}')
            print(f'JSON method type: {type(response.json)}')
            
            # Test if json() is async or sync
            json_result = response.json()
            print(f'JSON result type: {type(json_result)}')
            print(f'Is coroutine: {asyncio.iscoroutine(json_result)}')
            
            if asyncio.iscoroutine(json_result):
                print("⚠️  response.json() returns a coroutine - need to await it")
                actual_json = await json_result
                print(f'Awaited result type: {type(actual_json)}')
                print(f'Sample data: {list(actual_json.keys()) if isinstance(actual_json, dict) else actual_json}')
            else:
                print("✅ response.json() returns data directly")
                print(f'Sample data: {list(json_result.keys()) if isinstance(json_result, dict) else json_result}')
                
        except Exception as e:
            print(f'❌ Error: {e}')
            print(f'Error type: {type(e)}')


async def test_godot_client_behavior():
    """Test how our GodotClient implementation behaves"""
    print("\n=== Testing GodotClient Behavior ===")
    
    client = GodotClient('https://httpbin.org')
    try:
        # Test with a working endpoint that returns JSON
        result = await client.health_check()
        print(f'Health check result type: {type(result)}')
        print(f'Health check result: {result}')
        print("✅ GodotClient health_check works")
        
    except Exception as e:
        print(f'❌ GodotClient error: {e}')
        print(f'Error type: {type(e)}')
    finally:
        await client.close()


async def test_mcp_types():
    """Test MCP type imports and usage"""
    print("\n=== Testing MCP Types ===")
    
    try:
        from mcp.types import ListToolsRequest, CallToolRequest
        print("✅ ListToolsRequest and CallToolRequest available in mcp.types")
        print(f'ListToolsRequest: {ListToolsRequest}')
        print(f'CallToolRequest: {CallToolRequest}')
        
        # Test creating instances
        list_req = ListToolsRequest()
        call_req = CallToolRequest(name="test", arguments={})
        print("✅ Can create request instances")
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        
        # Check what's actually available
        try:
            import mcp.types as types
            available = [attr for attr in dir(types) if 'Request' in attr]
            print(f"Available request types: {available}")
        except Exception as inner_e:
            print(f"Can't check available types: {inner_e}")


async def main():
    """Run all diagnostic tests"""
    print("🔍 Running MCP Server Test Diagnostics\n")
    
    await test_httpx_response_behavior()
    await test_godot_client_behavior() 
    await test_mcp_types()
    
    print("\n🏁 Diagnostics complete!")


if __name__ == "__main__":
    asyncio.run(main())