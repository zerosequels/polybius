#!/bin/bash

# Godot MCP Plugin Installation Script

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path_to_godot_project>"
    echo "Example: $0 /path/to/my-godot-project"
    exit 1
fi

PROJECT_PATH="$1"
PLUGIN_SOURCE="./godot-plugin/addons/claude_mcp"
PLUGIN_DEST="$PROJECT_PATH/addons/claude_mcp"

# Validate source exists
if [ ! -d "$PLUGIN_SOURCE" ]; then
    echo "Error: Plugin source directory not found: $PLUGIN_SOURCE"
    exit 1
fi

# Validate target project exists
if [ ! -f "$PROJECT_PATH/project.godot" ]; then
    echo "Error: Not a valid Godot project (project.godot not found): $PROJECT_PATH"
    exit 1
fi

# Create addons directory if it doesn't exist
mkdir -p "$PROJECT_PATH/addons"

# Copy plugin
echo "Installing Claude MCP plugin to: $PLUGIN_DEST"
cp -r "$PLUGIN_SOURCE" "$PLUGIN_DEST"

# Verify installation
if [ -f "$PLUGIN_DEST/plugin.cfg" ]; then
    echo "✅ Plugin installed successfully!"
    echo "📁 Files installed:"
    ls -la "$PLUGIN_DEST"
    echo ""
    echo "🔧 Next steps:"
    echo "1. Open your Godot project"
    echo "2. Go to Project → Project Settings → Plugins"
    echo "3. Enable 'Claude MCP Server' plugin"
    echo "4. Check console for 'HTTP server started on port 8080'"
else
    echo "❌ Installation failed - plugin.cfg not found"
    exit 1
fi