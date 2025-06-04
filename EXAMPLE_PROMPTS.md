# Polybius Example Prompts & Testing Guide

> **Purpose:** End-to-end integration testing prompts for Claude Desktop ↔ MCP Server ↔ Godot Plugin  
> **Last Updated:** 2025-06-03  
> **Prerequisites:** Godot running with Claude MCP plugin enabled, Claude Desktop connected

## 🏥 **1. Health & Connectivity Tests**

### Test: Basic Connectivity
**Prompt:** `Check if the Godot plugin is running and accessible`

**Expected Outcome:**
- ✅ Message: "Godot plugin is running. Status: ok" 
- ✅ No connection errors

### Test: Tool Discovery
**Prompt:** `What Godot tools are available to me?`

**Expected Outcome:**
- ✅ List showing 6 tools: `create_scene`, `open_scene`, `get_current_scene`, `add_node`, `create_script`, `godot_health_check`
- ✅ Each tool shows description and parameters

---

## 🎬 **2. Scene Management Tests**

### Test: Get Current Scene (Empty State)
**Prompt:** `What scene is currently open in Godot?`

**Expected Outcome:**
- ✅ Message: "No scene currently open" OR current scene details if one exists

### Test: Create New Scene
**Prompt:** `Create a new scene called "TestLevel"`

**Expected Outcome:**
- ✅ Message: "Scene 'TestLevel' created successfully at res://scenes/TestLevel.tscn"
- ✅ Scene opens in Godot editor
- ✅ File appears in Godot FileSystem dock

### Test: Create Scene with Custom Path
**Prompt:** `Create a scene named "MainMenu" at the path "res://ui/MainMenu.tscn"`

**Expected Outcome:**
- ✅ Message: "Scene 'MainMenu' created successfully at res://ui/MainMenu.tscn"
- ✅ `ui/` directory created automatically
- ✅ Scene opens in Godot editor

### Test: Get Current Scene (With Scene Open)
**Prompt:** `What scene is currently open now?`

**Expected Outcome:**
- ✅ Scene name, path, type (Node), and child count displayed
- ✅ Should match the scene you just created

### Test: Open Existing Scene
**Prompt:** `Open the scene at "res://scenes/TestLevel.tscn"`

**Expected Outcome:**
- ✅ Message: "Scene opened successfully: res://scenes/TestLevel.tscn"
- ✅ Scene switches in Godot editor

---

## 🧩 **3. Node Management Tests**

### Test: Add Basic Node
**Prompt:** `Add a Node2D called "Player" to the current scene`

**Expected Outcome:**
- ✅ Message: "Node 'Player' of type 'Node2D' added successfully"
- ✅ Node appears in Godot Scene dock
- ✅ Node is child of scene root

### Test: Add UI Node
**Prompt:** `Add a Label node named "ScoreLabel" to the scene`

**Expected Outcome:**
- ✅ Message: "Node 'ScoreLabel' of type 'Label' added successfully"
- ✅ Label node visible in Scene dock

### Test: Add Node with Parent Path
**Prompt:** `Add a Sprite2D called "PlayerSprite" as a child of the Player node`

**Expected Outcome:**
- ✅ Message: "Node 'PlayerSprite' of type 'Sprite2D' added successfully"
- ✅ Node appears under Player in Scene hierarchy

### Test: Add Multiple Node Types
**Prompt:** `Add these nodes to the scene: a Button called "StartButton", a Timer called "GameTimer", and a Camera2D called "MainCamera"`

**Expected Outcome:**
- ✅ All three nodes created successfully
- ✅ Each appears in Scene dock with correct types

---

## 📜 **4. Script Management Tests**

### Test: Create Basic Script
**Prompt:** `Create a script at "res://scripts/player.gd" with basic player movement code`

**Expected Outcome:**
- ✅ Message: "Script created successfully at res://scripts/player.gd"
- ✅ File appears in Godot FileSystem dock
- ✅ `scripts/` directory created automatically

### Test: Create Script with Attachment
**Prompt:** `Create a script at "res://scripts/ui.gd" and attach it to the ScoreLabel node`

**Expected Outcome:**
- ✅ Message: "Script created successfully at res://scripts/ui.gd and attached to node ScoreLabel"
- ✅ Script icon appears next to ScoreLabel in Scene dock

### Test: Create Script with Custom Content
**Prompt:** `Create a script at "res://scripts/game_manager.gd" with this content:
extends Node

var score = 0

func _ready():
    print("Game started!")

func add_score(points):
    score += points
    print("Score: ", score)`

**Expected Outcome:**
- ✅ Script created with exact content provided
- ✅ File readable in Godot script editor

---

## 🔄 **5. Workflow Integration Tests**

### Test: Complete Game Object Creation
**Prompt:** `Create a complete player setup: make a new scene called "Player", add a CharacterBody2D node called "PlayerBody", add a Sprite2D child called "PlayerSprite", and create a player controller script at "res://scripts/player_controller.gd" attached to PlayerBody`

**Expected Outcome:**
- ✅ Scene "Player" created and opened
- ✅ Node hierarchy: PlayerBody (CharacterBody2D) → PlayerSprite (Sprite2D)
- ✅ Script created and attached to PlayerBody
- ✅ All operations complete without errors

### Test: Scene Switching Workflow
**Prompt:** `Switch back to the TestLevel scene, then add a Node called "PlayerSpawn" to mark where the player should appear`

**Expected Outcome:**
- ✅ TestLevel scene opens
- ✅ PlayerSpawn node added successfully
- ✅ Previous work (Player, ScoreLabel, etc.) still present

---

## ⚠️ **6. Error Handling Tests**

### Test: Invalid Node Type
**Prompt:** `Add a FakeNodeType called "BadNode" to the scene`

**Expected Outcome:**
- ✅ Error message: "Invalid node type: FakeNodeType" or similar
- ✅ No crash or unexpected behavior

### Test: Open Non-existent Scene
**Prompt:** `Open the scene at "res://nonexistent/scene.tscn"`

**Expected Outcome:**
- ✅ Error message: "Scene file not found" or similar
- ✅ Current scene remains open

### Test: Invalid Parent Path
**Prompt:** `Add a Node called "TestNode" as a child of "NonExistentParent"`

**Expected Outcome:**
- ✅ Error message: "Parent node not found: NonExistentParent"
- ✅ Node not added to scene

---

## 🎯 **Success Criteria Summary**

**✅ All tests pass if:**
- No connection errors or timeouts
- All successful operations reflect in Godot editor immediately
- Error cases handled gracefully with clear messages
- File system operations create proper directory structures
- Node hierarchy matches requests exactly
- Scripts attach correctly and contain expected content

**🔍 Verification Steps:**
1. Watch Godot Scene dock for node changes
2. Check Godot FileSystem dock for new files/folders  
3. Open created scripts in Godot to verify content
4. Test script attachment by checking node properties
5. Verify scene switching works correctly

---

## 💡 **Additional Example Prompts**

### Creative Workflows
- `Help me create a basic 2D platformer player character with movement script`
- `Set up a main menu scene with start and quit buttons`
- `Create a simple enemy with basic AI behavior script`
- `Build a collectible item with pickup functionality`

### Advanced Combinations
- `Create a game manager that tracks score and handles level transitions`
- `Set up a player health system with UI display`
- `Create a dialogue system with text display and progression`
- `Build a simple inventory system for a 2D game`

### Project Organization
- `Organize my project: create folders for scenes, scripts, sprites, and audio`
- `Set up a clean project structure for a puzzle game`
- `Create template scenes for different game object types`

### Debugging & Inspection
- `Show me the current scene structure and all nodes`
- `List all scripts in my project and what they're attached to`
- `Check if there are any scenes without proper node hierarchies`

---

## 🚨 **Troubleshooting Common Issues**

### Connection Problems
- **Symptom**: "Cannot connect to Godot plugin"
- **Check**: Godot running? Plugin enabled? HTTP server on port 8080?
- **Fix**: Restart Godot, re-enable plugin, check console for errors

### Scene Operations Fail
- **Symptom**: Scene creation/opening fails
- **Check**: File permissions? Valid paths? Godot project open?
- **Fix**: Ensure Godot project is open and file system is writable

### Node Addition Fails  
- **Symptom**: Nodes not appearing in scene
- **Check**: Scene currently open? Valid node type? Parent exists?
- **Fix**: Open a scene first, use supported node types

### Script Creation Issues
- **Symptom**: Scripts not created or attached
- **Check**: Valid file paths? Directory permissions? Node exists for attachment?
- **Fix**: Use `res://` paths, ensure target nodes exist