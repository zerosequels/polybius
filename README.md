# Polybius - Godot MCP Server

> **✨ Revolutionary AI-Powered Game Development** - Enabling Claude Desktop to directly control the Godot game engine editor through natural language.

## 💖 Support Development

**Love this project? Help fuel its future!** ☕

Polybius represents hundreds of hours of dedicated development to bridge AI and game development. Your support directly enables:
- 🚀 **New feature development** - More tools, better UI support, advanced capabilities
- 🐛 **Bug fixes and improvements** - Keeping everything running smoothly
- 📚 **Documentation and tutorials** - Making it easier for everyone to use
- 🌟 **Community growth** - Building the future of AI-assisted game development

**[☕ Support on Ko-fi](https://ko-fi.com/zerosequels)**

Every contribution, no matter the size, makes a real difference. Join the supporters helping to revolutionize how we create games!

---

## 🎮 Overview

**Polybius** is a comprehensive MCP (Model Context Protocol) server that creates a seamless bridge between Claude Desktop and the Godot game engine editor. Through natural language commands, you can now build entire games, manage assets, configure projects, and create complex scenes - all powered by AI.

### 🏗️ Architecture Components

1. **🔌 Godot Plugin** (`godot-plugin/`) - GDScript editor plugin exposing Godot functionality via HTTP API
2. **🐍 MCP Server** (`mcp-server/`) - Python MCP server implementing 21+ tools for complete game development workflow

```
Claude Desktop ↔ MCP Protocol (JSON-RPC 2.0) ↔ Python MCP Server ↔ HTTP API ↔ Godot Plugin ↔ Godot Editor
```

---

## ✨ Current Features (Phase 2 Complete!)

### 🎬 **Scene Management** (11 Tools)
- ✅ **`create_scene`** - Create scenes with smart root node selection (Node2D, Node3D, Control, Node)
- ✅ **`open_scene`** - Open existing scene files
- ✅ **`get_current_scene`** - Retrieve current scene information
- ✅ **`list_scenes`** - List all project scenes
- ✅ **`duplicate_scene`** - Copy existing scenes with automatic naming
- ✅ **`delete_scene`** - Safely remove scene files with confirmation
- ✅ **`add_node`** - Add 11+ node types (UI, Physics, Graphics, Audio, etc.)
- ✅ **`delete_node`** - Remove nodes with safety protection
- ✅ **`move_node`** - Reparent and reorder scene nodes
- ✅ **`get_node_properties`** - Read all node property values
- ✅ **`set_node_properties`** - Batch modify node properties

### 📝 **Script Management** (5 Tools)
- ✅ **`create_script`** - Generate GDScript files with templates and node attachment
- ✅ **`list_scripts`** - Enumerate all project scripts
- ✅ **`read_script`** - View script content
- ✅ **`modify_script`** - Edit existing scripts
- ✅ **`delete_script`** - Safely remove script files

### 🎨 **Asset Management** (3 Tools) 🆕 **Phase 2**
- ✅ **`import_asset`** - Import external files (images, audio, models, fonts) with organized storage
- ✅ **`list_resources`** - Browse project resources with filtering and metadata
- ✅ **`organize_assets`** - Move/rename assets with reference tracking

### ⚙️ **Project Management** (3 Tools) 🆕 **Phase 2**
- ✅ **`get_project_settings`** - Read project.godot configuration
- ✅ **`modify_project_settings`** - Update project settings programmatically
- ✅ **`export_project`** - Build/export projects with preset management

### 🔧 **Health & Diagnostics**
- ✅ **`godot_health_check`** - Verify plugin connectivity and status
- ✅ **22 HTTP Endpoints** - Complete REST API for all functionality

---

## 🚀 Planned Features (Phase 3: UI Management)

### 🎯 **UI Positioning & Anchoring** (Critical for proper UI layout)
- 🔄 **`set_control_anchors`** - Set precise anchor points
- 🔄 **`center_control`** - Auto-center UI elements (fixes top-left clustering!)
- 🔄 **`position_control`** - Absolute positioning with anchor handling
- 🔄 **`fit_control_to_parent`** - Fill parent containers
- 🔄 **`set_anchor_margins`** - Precise margin control
- 🔄 **`configure_size_flags`** - Control expand/shrink behavior
- 🔄 **`setup_control_rect`** - Complete position/size with anchor math

### 🎨 **Smart UI Creation Helpers**
- 🔄 **`create_centered_ui`** - Auto-centered UI elements
- 🔄 **`create_fullscreen_ui`** - Proper screen-filling UI
- 🔄 **`setup_ui_container_with_children`** - Containers with positioned children
- 🔄 **`apply_common_ui_patterns`** - Pre-configured layouts (menus, HUDs, dialogs)

### 📐 **UI Layout Management**
- 🔄 **`create_ui_layout`** - Containers (VBox, HBox, Grid, etc.)
- 🔄 **`set_anchor_preset`** - Common presets (center, full rect, corners)
- 🔄 **`align_controls`** - Multi-element alignment
- 🔄 **`distribute_controls`** - Even spacing distribution

### 🎭 **UI Theme Management**
- 🔄 **`create_theme`** - Theme resource creation
- 🔄 **`apply_theme`** - Theme application to nodes/scenes
- 🔄 **`modify_theme_properties`** - Colors, fonts, styles
- 🔄 **`import_theme`** / **`export_theme`** - Theme file management

### 🧩 **UI Component Management**
- 🔄 **`create_ui_component`** - Common components (dialogs, menus, panels)
- 🔄 **`configure_button`** - Button text, icons, styling
- 🔄 **`setup_label`** - Label configuration and alignment
- 🔄 **`create_input_field`** - LineEdit/TextEdit setup
- 🔄 **`setup_progress_bar`** - Progress indicators
- 🔄 **`create_list_container`** - ItemList/Tree components

---

## 🛠️ Installation

### 📦 Godot Plugin Installation

1. **Copy Plugin Files**
   ```bash
   cp -r godot-plugin/addons/claude_mcp/ /path/to/your/project/addons/
   ```

2. **Enable in Godot**
   - Open your Godot project
   - Navigate to **Project → Project Settings → Plugins**
   - Enable **"Claude MCP Server"** plugin
   - Plugin starts HTTP server on `127.0.0.1:8080`

### 🐍 MCP Server Installation

1. **Install Dependencies**
   ```bash
   cd mcp-server
   pip install -r requirements.txt
   ```

2. **Configure Claude Desktop**
   
   Add to your `claude_desktop_config.json`:
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

3. **Restart Claude Desktop** to load the MCP server

---

## 🎯 Usage Examples

Once installed, Claude can control Godot through natural language:

### 🎬 **Scene Creation**
```
"Create a new 2D platformer scene called 'Level1' with a CharacterBody2D player"
"Add a tilemap background and some platform collision shapes"
"Duplicate this scene and call it 'Level2' in the levels folder"
```

### 🎨 **Asset Management**
```
"Import these sprites from my Desktop into the textures folder"
"Organize all the audio files into subfolders by type"
"List all the image assets in the project with their sizes"
```

### ⚙️ **Project Configuration**
```
"Set the main scene to MainMenu.tscn"
"Change the window size to 1920x1080"
"Export the project as a Windows executable"
```

### 📝 **Script Development**
```
"Create a player controller script with basic movement"
"Add a jump mechanic to the existing player script"
"List all scripts and show me the health system code"
```

---

## 📊 Current Statistics

- **🛠️ Total MCP Tools**: 21 implemented
- **🌐 HTTP Endpoints**: 22 functional REST endpoints
- **🎮 Supported Node Types**: 11 core Godot node types
- **📁 Asset Types**: 7 categories (image, audio, model, texture, font, scene, script)
- **✅ Test Coverage**: 100% HTTP endpoints, manual MCP testing
- **💻 Lines of Code**: ~2,100 (estimated)

---

## 🚀 Development Commands

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

---

## 🔧 Known Limitations

- **Single Scene Focus**: Tools operate on currently open scene
- **Node Type Coverage**: Limited to 11 common Godot node types
- **No Undo Integration**: Scene modifications bypass Godot's undo system
- **Local Network Only**: HTTP server bound to localhost for security

---

## 🌟 Contributing

This project is actively developed and welcomes contributions! Whether it's:
- 🐛 **Bug Reports** - Help us identify and fix issues
- 💡 **Feature Requests** - Suggest new tools and capabilities  
- 📝 **Documentation** - Improve guides and examples
- 💻 **Code Contributions** - Implement new MCP tools

**[☕ Support Development](https://ko-fi.com/zerosequels)** to help prioritize new features!

---

## 📄 License

Open source project - check repository for license details.

---

**Ready to revolutionize your game development workflow? Install Polybius and start building games with AI today!** 🚀🎮