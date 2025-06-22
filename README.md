# Polybius - Godot MCP Server

> **✨ Revolutionary AI-Powered Game Development** - Enabling Claude Desktop to directly control the Godot game engine editor through natural language.

## 💖 Support Development

**Love this project? Help fuel its future!** ☕

Polybius represents hundreds of hours of dedicated development to bridge AI and game development. Your support directly enables:
- 🚀 **New feature development** - More tools, better UI support, advanced capabilities
- 🐛 **Bug fixes and improvements** - Keeping everything running smoothly
- 📚 **Documentation and tutorials** - Making it easier for everyone to use
- 🌟 **Community growth** - Building the future of AI-assisted game development
- 🎮 **Exclusive weekly game jam access** - Join our private Discord community of AI-powered game developers with automated weekly game jams every Wednesday. Connect with fellow creators exploring AI-assisted development, share your AI-generated game ideas, and participate in challenges designed for developers using Claude, ChatGPT, and other AI tools in their creative process

**[☕ Support on Ko-fi](https://ko-fi.com/zerosequels)**

Every contribution, no matter the size, makes a real difference. Join the supporters helping to revolutionize how we create games!

---

## 🎮 Overview

**Polybius** is a comprehensive MCP (Model Context Protocol) server that creates a seamless bridge between Claude Desktop and the Godot game engine editor. Through natural language commands, you can now build entire games, manage assets, configure projects, and create complex scenes - all powered by AI.

### 🏗️ Architecture Components

1. **🔌 Godot Plugin** (`godot-plugin/`) - GDScript editor plugin exposing Godot functionality via HTTP API
2. **🐍 MCP Server** (`mcp-server/`) - Python MCP server implementing 50+ tools for complete game development workflow

```
Claude Desktop ↔ MCP Protocol (JSON-RPC 2.0) ↔ Python MCP Server ↔ HTTP API ↔ Godot Plugin ↔ Godot Editor
```

---

## ✨ Current Features (Universal Node Support + Complete Phase 3!)

### 🎬 **Scene Management** (13 Tools)
- ✅ **`create_scene`** - Create scenes with smart root node selection (Node2D, Node3D, Control, Node)
- ✅ **`open_scene`** - Open existing scene files
- ✅ **`get_current_scene`** - Retrieve current scene information
- ✅ **`list_scenes`** - List all project scenes
- ✅ **`duplicate_scene`** - Copy existing scenes with automatic naming
- ✅ **`delete_scene`** - Safely remove scene files with confirmation
- ✅ **`add_node`** - **Universal node support** - Add any of 500+ Godot node types (UI, Physics, Graphics, Audio, 3D, Advanced, etc.)
- ✅ **`delete_node`** - Remove nodes with safety protection
- ✅ **`move_node`** - Reparent and reorder scene nodes
- ✅ **`get_node_properties`** - Read all node property values
- ✅ **`set_node_properties`** - Batch modify node properties
- ✅ **`get_node_class_info`** 🆕 - Get detailed information about any Godot node class
- ✅ **`list_node_classes`** 🆕 - Discover all available Godot node types with filtering

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

### 🎯 **UI Control & Positioning** (7 Tools) 🆕 **Phase 3**
- ✅ **`set_control_anchors`** - Set precise anchor points for proper Control positioning
- ✅ **`center_control`** - Auto-center UI elements (fixes top-left clustering!)
- ✅ **`position_control`** - Absolute positioning with anchor-aware calculations
- ✅ **`fit_control_to_parent`** - Fill parent containers with configurable margins
- ✅ **`set_anchor_margins`** - Precise margin control from anchor points
- ✅ **`configure_size_flags`** - Control expand/shrink behavior in containers
- ✅ **`setup_control_rect`** - Complete position/size with anchor calculation

### 🎨 **Smart UI Creation Helpers** (4 Tools) 🆕 **Phase 3 Smart UI**
- ✅ **`create_centered_ui`** - Create UI elements that are automatically centered
- ✅ **`create_fullscreen_ui`** - Create UI that properly fills the screen
- ✅ **`setup_ui_container_with_children`** - Create container with properly positioned child elements
- ✅ **`apply_common_ui_patterns`** - Apply pre-configured layouts (main menu, HUD, dialog, etc.)

### 🔧 **Health & Diagnostics**
- ✅ **`godot_health_check`** - Verify plugin connectivity and status
- ✅ **51 HTTP Endpoints** - Complete REST API for all functionality

---

## 🚀 Planned Features (Phase 3 Remaining & Phase 4)

### 🎯 **UI Positioning & Anchoring** ✅ **COMPLETED**
- ✅ **`set_control_anchors`** - Set precise anchor points
- ✅ **`center_control`** - Auto-center UI elements (fixes top-left clustering!)
- ✅ **`position_control`** - Absolute positioning with anchor handling
- ✅ **`fit_control_to_parent`** - Fill parent containers
- ✅ **`set_anchor_margins`** - Precise margin control
- ✅ **`configure_size_flags`** - Control expand/shrink behavior
- ✅ **`setup_control_rect`** - Complete position/size with anchor math

### 🎨 **Smart UI Creation Helpers** ✅ **COMPLETED**
- ✅ **`create_centered_ui`** - Auto-centered UI elements
- ✅ **`create_fullscreen_ui`** - Proper screen-filling UI
- ✅ **`setup_ui_container_with_children`** - Containers with positioned children
- ✅ **`apply_common_ui_patterns`** - Pre-configured layouts (menus, HUDs, dialogs)

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

## 🛠️ API Documentation for Developers

### Python MCP Server API

#### Core Tool Categories

##### 🎬 Scene Management Tools
```python
# Create new scene
create_scene(name: str, path?: str, root_node_type: "Node2D"|"Node3D"|"Control"|"Node")

# Scene operations
open_scene(path: str)
get_current_scene() -> SceneInfo
list_scenes() -> SceneInfo[]
duplicate_scene(source_path: str, new_path: str)
delete_scene(path: str)

# Node operations
add_node(node_type: str, name?: str, parent_path?: str)
delete_node(node_path: str)
move_node(node_path: str, new_parent_path: str, position?: int)
get_node_properties(node_path: str) -> NodeProperties
set_node_properties(node_path: str, properties: dict)

# Node discovery
get_node_class_info(class_name: str) -> ClassInfo
list_node_classes(category?: str, search?: str) -> NodeClass[]
```

##### 📝 Script Management Tools
```python
# Script operations
create_script(path: str, content?: str, node_path?: str)
list_scripts() -> ScriptInfo[]
read_script(path: str) -> str
modify_script(path: str, content: str)
delete_script(path: str)
```

##### 🎨 Asset Management Tools
```python
# Asset operations
import_asset(source_path: str, destination_path?: str, asset_type?: str)
list_resources(directory?: str, filter?: str) -> ResourceInfo[]
organize_assets(source_path: str, destination_path: str)
```

##### ⚙️ Project Management Tools
```python
# Project configuration
get_project_settings() -> ProjectSettings
modify_project_settings(settings: dict)
export_project(preset_name: str, output_path?: str)
```

##### 🎯 UI Control & Positioning Tools
```python
# Control positioning
set_control_anchors(node_path: str, anchor_left: float, anchor_top: float, 
                   anchor_right: float, anchor_bottom: float)
center_control(node_path: str)
position_control(node_path: str, x: float, y: float)
fit_control_to_parent(node_path: str, margin?: float)

# Smart UI creation
create_centered_ui(node_type: str, name: str, size?: [int, int])
create_fullscreen_ui(node_type: str, name: str, margin?: float)
setup_ui_container_with_children(container_type: str, children: UIChild[])
apply_common_ui_patterns(pattern: str, config: dict)
```

### HTTP API Endpoints (Godot Plugin)

The Godot plugin exposes 51+ REST endpoints on `http://127.0.0.1:8080`:

#### Health & Diagnostics
```http
GET /health                    # Plugin connectivity check
GET /errors                    # Recent error log
```

#### Scene Management
```http
POST /scene/create            # Create new scene
GET  /scene/current           # Get current scene info
POST /scene/open              # Open existing scene
GET  /scene/list              # List all scenes
POST /scene/duplicate         # Copy scene
DELETE /scene                 # Delete scene

POST /node/add                # Add node to scene
DELETE /node                  # Remove node
POST /node/move               # Reparent/reorder node
GET  /node/properties         # Get node properties
POST /node/properties         # Set node properties
GET  /node/classes            # List available node types
GET  /node/class-info         # Get class documentation
```

#### Script Management
```http
POST /script/create           # Create GDScript file
GET  /script/list             # List all scripts
GET  /script/read             # Read script content
POST /script/modify           # Edit script
DELETE /script                # Delete script
```

#### Asset Management
```http
POST /asset/import            # Import external file
GET  /asset/list              # List project resources
POST /asset/organize          # Move/rename assets
```

#### Project Configuration
```http
GET  /project/settings        # Read project.godot
POST /project/settings        # Update configuration
POST /project/export          # Build/export project
```

#### UI Control & Positioning
```http
POST /control/anchors         # Set anchor points
POST /control/center          # Center UI element
POST /control/position        # Absolute positioning
POST /control/fit-parent      # Fill parent container
POST /ui/create-centered      # Smart centered creation
POST /ui/create-fullscreen    # Smart fullscreen creation
POST /ui/setup-container      # Container with children
POST /ui/apply-pattern        # Apply UI layout pattern
```

### Error Handling

All API endpoints return standardized responses:

```json
// Success response
{
  "success": true,
  "data": { /* result data */ },
  "message": "Operation completed successfully"
}

// Error response  
{
  "success": false,
  "error": "Error description",
  "details": { /* additional error context */ }
}
```

### Type Definitions

```python
# Common data structures
class SceneInfo:
    path: str
    name: str
    root_node_type: str
    is_current: bool

class NodeProperties:
    name: str
    type: str
    properties: dict
    children: list[str]

class ResourceInfo:
    path: str
    type: str
    size: int
    imported: bool
```

---

## 🎯 Usage Examples

Once installed, Claude can control Godot through natural language:

### 🎬 **Scene Creation**
```
"Create a new 2D platformer scene called 'Level1' with a CharacterBody2D player"
"Add a TileMap background and some StaticBody2D platform collision shapes"
"Add a Camera2D with follow behavior and an AudioStreamPlayer2D for ambient sound"
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
"What node types are available for creating UI elements?"
"Get information about the RigidBody3D class and its properties"
```

### 🎯 **UI Control & Positioning**
```
"Create a main menu with properly centered buttons that don't cluster in the top-left"
"Set up a HUD with a health bar anchored to the top-left and score in the top-right"
"Center the game over dialog both horizontally and vertically on screen"
"Make the pause menu fill the entire screen with proper margins"
"Position the inventory panel at the bottom-right with anchor margins"
```

### 🎨 **Smart UI Creation Helpers**
```
"Create a centered 'Start Game' button with 200x50 size that's automatically positioned"
"Create a fullscreen background panel for the main menu with 20 pixel margins"
"Apply the main_menu UI pattern with title 'Epic Adventure' and custom buttons"
"Set up a game HUD using the hud pattern with health and score displays"
"Create a pause dialog using the dialog pattern with title 'Game Paused'"
"Set up a main menu container with title and three buttons in one command"
```

---

## 📊 Current Statistics

- **🛠️ Total MCP Tools**: 50 implemented (including 2 new Node Discovery tools)
- **🌐 HTTP Endpoints**: 51 functional REST endpoints  
- **🎮 Supported Node Types**: **All valid Godot node classes (500+ types)** - Universal support via ClassDB
- **📁 Asset Types**: 7 categories (image, audio, model, texture, font, scene, script)
- **🎯 UI Features**: Complete anchor/positioning system + Smart UI creation helpers + Universal node discovery
- **✅ Test Coverage**: 100% HTTP endpoints, manual MCP testing
- **💻 Lines of Code**: ~5,200 (estimated)

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

This project is licensed under the MIT License - use it however you want! I hope you find this tool handy for your game development adventures. Feel free to modify, distribute, and build upon it to create amazing things.

---

**Ready to revolutionize your game development workflow? Install Polybius and start building games with AI today!** 🚀🎮