import asyncio
import logging
from typing import Any, Sequence
from mcp.server import Server
from mcp.types import Resource, Tool, TextContent, ImageContent, EmbeddedResource
from mcp.server.stdio import stdio_server

from godot_client import GodotClient
from tools.scene_tools import get_scene_tools, handle_scene_tool
from tools.script_tools import get_script_tools, handle_script_tool
from tools.error_tools import get_error_tools, handle_error_tool
from tools.asset_tools import get_asset_tools, handle_asset_tool
from tools.project_tools import get_project_tools, handle_project_tool
from tools.theme_tools import get_theme_tools, handle_theme_tool
from tools.animation_tools import get_animation_tools, handle_animation_tool

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
        logger.info("🛠️  Registered tools: scene management, script creation, asset management, project settings, theme management, animation & interaction, error monitoring, health check")
    
    def setup_handlers(self):
        @self.server.list_tools()
        async def list_tools() -> list[Tool]:
            """List all available tools"""
            tools = []
            tools.extend(get_scene_tools())
            tools.extend(get_script_tools())
            tools.extend(get_error_tools())
            tools.extend(get_asset_tools())
            tools.extend(get_project_tools())
            tools.extend(get_theme_tools())
            tools.extend(get_animation_tools())
            
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
            
            # Handle error tools
            error_tools = [tool.name for tool in get_error_tools()]
            if name in error_tools:
                return await handle_error_tool(name, arguments, self.godot_client)
            
            # Handle asset tools
            asset_tools = [tool.name for tool in get_asset_tools()]
            if name in asset_tools:
                return await handle_asset_tool(name, arguments, self.godot_client)
            
            # Handle project tools
            project_tools = [tool.name for tool in get_project_tools()]
            if name in project_tools:
                return await handle_project_tool(name, arguments, self.godot_client)
            
            # Handle theme tools
            theme_tools = [tool.name for tool in get_theme_tools()]
            if name in theme_tools:
                return await handle_theme_tool(name, arguments, self.godot_client)
            
            # Handle animation tools
            animation_tools = [tool.name for tool in get_animation_tools()]
            if name in animation_tools:
                return await handle_animation_tool(name, arguments, self.godot_client)
            
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