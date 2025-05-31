# Godot MCP Server

An MCP (Model Context Protocol) server that enables Claude Desktop to interact with the Godot game engine editor.

## Overview

This project consists of two main components:

1. **Godot Plugin** (`godot-plugin/`) - A Godot editor plugin that exposes editor functionality via HTTP API
2. **MCP Server** (`mcp-server/`) - A Python MCP server that translates Claude's requests into Godot operations

## Features

### Scene Management
- Create new scenes
- Open existing scenes  
- Get current scene information
- Add nodes to scenes

### Script Management
- Create GDScript files
- Attach scripts to nodes

### Editor Integration
- Real-time communication with Godot editor
- Health checking and status monitoring

## Installation

### Godot Plugin Installation

1. Copy the `godot-plugin/addons/claude_mcp/` folder to your Godot project's `addons/` directory
2. Open your Godot project
3. Go to Project → Project Settings → Plugins
4. Enable the "Claude MCP Server" plugin
5. The plugin will start an HTTP server on port 8080

### MCP Server Installation

1. Install dependencies:
   ```bash
   cd mcp-server
   pip install -r requirements.txt
   ```

2. Configure Claude Desktop by adding to `claude_desktop_config.json`:
   ```json
   {
     "mcpServers": {
       "godot": {
         "command": "python",
         "args": ["/path/to/polybius/mcp-server/src/server.py"]
       }
     }
   }
   ```

## Usage

Once both components are running:

1. Open Godot with the plugin enabled
2. Start Claude Desktop
3. Claude can now interact with your Godot project using natural language

### Example Commands

- "Create a new scene called 'MainMenu'"
- "Add a Button node named 'StartButton' to the current scene"
- "Create a script for the player character"
- "Open the game scene and add a camera"

## Development Status

This is an initial implementation with basic functionality. The architecture supports easy extension for additional Godot editor operations.

## Architecture

```
Claude Desktop ↔ MCP Protocol ↔ Python MCP Server ↔ HTTP API ↔ Godot Plugin ↔ Godot Editor
```

The system uses:
- **MCP Protocol**: JSON-RPC 2.0 for Claude communication
- **HTTP API**: REST endpoints for Godot plugin communication  
- **GDScript**: Editor plugin implementation
- **Python**: MCP server with asyncio for concurrency