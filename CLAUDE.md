# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Polybius project - a Godot MCP Server that enables Claude Desktop to interact with the Godot game engine editor. The project consists of two main components:

1. **Godot Plugin** (`godot-plugin/addons/claude_mcp/`) - GDScript editor plugin that exposes Godot functionality via HTTP API
2. **MCP Server** (`mcp-server/src/`) - Python MCP server implementing Model Context Protocol

## Development Commands

### MCP Server
```bash
# Install dependencies  
cd mcp-server && pip install -r requirements.txt

# Run MCP server (typically called by Claude Desktop)
python mcp-server/src/server.py
```

### Testing
```bash
# Test HTTP endpoints (requires Godot plugin running)
curl http://127.0.0.1:8080/health

# Test MCP server tools
python -m mcp-server.src.server
```

## Architecture

**Communication Flow:**
```
Claude Desktop ↔ MCP Protocol (JSON-RPC 2.0) ↔ Python MCP Server ↔ HTTP API ↔ Godot Plugin ↔ Godot Editor
```

**Key Components:**
- `godot-plugin/addons/claude_mcp/plugin.gd` - Main EditorPlugin entry point
- `godot-plugin/addons/claude_mcp/http_server.gd` - HTTP server for API endpoints  
- `godot-plugin/addons/claude_mcp/godot_api.gd` - Wrapper for Godot editor operations
- `mcp-server/src/server.py` - Main MCP server implementation
- `mcp-server/src/godot_client.py` - HTTP client for communicating with Godot plugin
- `mcp-server/src/tools/` - MCP tool implementations for different functionality areas

**Plugin Installation:**
The Godot plugin must be copied to a Godot project's `addons/` directory and enabled via Project Settings → Plugins.

**MCP Configuration:**
Add to Claude Desktop's `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "godot": {
      "command": "python", 
      "args": ["/absolute/path/to/polybius/mcp-server/src/server.py"]
    }
  }
}
```