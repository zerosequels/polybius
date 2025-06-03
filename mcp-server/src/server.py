import asyncio
import logging
from typing import Any, Sequence
from mcp.server import Server
from mcp.types import Resource, Tool, TextContent, ImageContent, EmbeddedResource
from mcp.server.stdio import stdio_server

from godot_client import GodotClient
from tools.scene_tools import get_scene_tools, handle_scene_tool
from tools.script_tools import get_script_tools, handle_script_tool

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class GodotMCPServer:
    def __init__(self):
        logger.info("🔧 Initializing Godot MCP Server...")
        self.server = Server("godot-mcp-server")
        self.godot_client = GodotClient()
        logger.info("📡 Setting up MCP tool handlers...")
        self.setup_handlers()
        logger.info("🛠️  Registered tools: scene management, script creation, health check")
    
    def setup_handlers(self):
        @self.server.list_tools()
        async def list_tools() -> list[Tool]:
            """List all available tools"""
            tools = []
            tools.extend(get_scene_tools())
            tools.extend(get_script_tools())
            
            # Add health check tool
            tools.append(Tool(
                name="godot_health_check",
                description="Check if Godot editor plugin is running and accessible",
                inputSchema={
                    "type": "object",
                    "properties": {}
                }
            ))
            
            return tools
        
        @self.server.call_tool()
        async def call_tool(name: str, arguments: dict) -> Sequence[TextContent | ImageContent | EmbeddedResource]:
            """Handle tool calls"""
            logger.info(f"Tool called: {name} with arguments: {arguments}")
            
            if name == "godot_health_check":
                result = await self.godot_client.health_check()
                if result.get("connected", True) and not result.get("error"):
                    return [TextContent(
                        type="text",
                        text=f"Godot plugin is running. Status: {result.get('status', 'unknown')}"
                    )]
                else:
                    return [TextContent(
                        type="text", 
                        text=f"Cannot connect to Godot plugin: {result.get('error', 'Unknown error')}"
                    )]
            
            # Handle scene tools
            scene_tools = [tool.name for tool in get_scene_tools()]
            if name in scene_tools:
                return await handle_scene_tool(name, arguments, self.godot_client)
            
            # Handle script tools  
            script_tools = [tool.name for tool in get_script_tools()]
            if name in script_tools:
                return await handle_script_tool(name, arguments, self.godot_client)
            
            # Unknown tool
            return [TextContent(
                type="text",
                text=f"Unknown tool: {name}"
            )]
    
    async def run(self):
        """Run the MCP server"""
        try:
            async with stdio_server() as streams:
                await self.server.run(
                    streams[0], streams[1], self.server.create_initialization_options()
                )
        finally:
            await self.godot_client.close()

async def main():
    """Main entry point"""
    logger.info("🚀 Starting Godot MCP Server...")
    logger.info("Server name: godot-mcp-server")
    logger.info("Communication: JSON-RPC over stdio")
    
    try:
        server = GodotMCPServer()
        logger.info("✅ MCP Server initialized successfully")
        logger.info("🔌 Waiting for MCP client connection...")
        await server.run()
    except Exception as e:
        logger.error(f"❌ Failed to start MCP server: {e}")
        raise

if __name__ == "__main__":
    asyncio.run(main())