#!/bin/bash

# Plugin Structure Verification Script

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path_to_godot_project>"
    echo "Example: $0 /path/to/my-godot-project"
    exit 1
fi

PROJECT_PATH="$1"
PLUGIN_PATH="$PROJECT_PATH/addons/claude_mcp"

echo "🔍 Verifying Claude MCP plugin installation..."
echo "Project: $PROJECT_PATH"
echo "Plugin path: $PLUGIN_PATH"
echo ""

# Check if plugin directory exists
if [ ! -d "$PLUGIN_PATH" ]; then
    echo "❌ Plugin directory not found: $PLUGIN_PATH"
    echo "💡 Run: ./install_plugin.sh $PROJECT_PATH"
    exit 1
fi

# Check required files
REQUIRED_FILES=(
    "plugin.cfg"
    "plugin.gd" 
    "http_server.gd"
    "godot_api.gd"
)

ALL_FOUND=true

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PLUGIN_PATH/$file" ]; then
        echo "✅ $file - Found"
    else
        echo "❌ $file - Missing"
        ALL_FOUND=false
    fi
done

echo ""

# Check for incorrect nested structure
NESTED_PATH="$PROJECT_PATH/addons/godot-plugin"
if [ -d "$NESTED_PATH" ]; then
    echo "⚠️  WARNING: Found nested structure at $NESTED_PATH"
    echo "   This will cause path resolution errors!"
    echo "   Remove the nested folder and use ./install_plugin.sh instead"
    echo ""
fi

if [ "$ALL_FOUND" = true ]; then
    echo "✅ Plugin structure is correct!"
    echo ""
    echo "🔧 Test HTTP server (after enabling plugin in Godot):"
    echo "   curl http://127.0.0.1:8080/health"
else
    echo "❌ Plugin structure has issues - reinstall required"
    exit 1
fi