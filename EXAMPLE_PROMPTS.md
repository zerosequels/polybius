# Polybius Example Prompts & Testing Guide

> **Purpose:** End-to-end integration testing prompts for Claude Desktop ↔ MCP Server ↔ Godot Plugin  
> **Last Updated:** 2025-06-10 (Phase 3: UI Positioning & Anchoring Added)  
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
- ✅ List showing 36 tools including new Phase 3 Smart UI and Layout Management tools
- ✅ Scene tools: `create_scene`, `open_scene`, `get_current_scene`, `list_scenes`, `duplicate_scene`, `delete_scene`
- ✅ Node tools: `add_node`, `delete_node`, `move_node`, `get_node_properties`, `set_node_properties`
- ✅ Script tools: `create_script`, `list_scripts`, `read_script`, `modify_script`, `delete_script`
- ✅ Asset tools: `import_asset`, `list_resources`, `organize_assets` 🆕 PHASE 2
- ✅ Project tools: `get_project_settings`, `modify_project_settings`, `export_project` 🆕 PHASE 2
- ✅ UI Control tools: `set_control_anchors`, `center_control`, `position_control`, `fit_control_to_parent`, `set_anchor_margins`, `configure_size_flags`, `setup_control_rect` 🆕 PHASE 3
- ✅ Smart UI tools: `create_centered_ui`, `create_fullscreen_ui`, `setup_ui_container_with_children`, `apply_common_ui_patterns` 🆕 PHASE 3 SMART UI
- ✅ Layout Management tools: `create_ui_layout`, `set_anchor_preset`, `align_controls`, `distribute_controls` 🆕 PHASE 3 UI LAYOUT
- ✅ Health tool: `godot_health_check`
- ✅ Each tool shows description and parameters

---

## 🎬 **2. Scene Management Tests**

### Test: Get Current Scene (Empty State)
**Prompt:** `What scene is currently open in Godot?`

**Expected Outcome:**
- ✅ Message: "No scene currently open" OR current scene details if one exists

### Test: Create New Scene (with Root Node Type Prompting)
**Prompt:** `Create a new scene called "TestLevel"`

**Expected Outcome:**
- ✅ Prompt: "Please specify what type of scene you want to create for 'TestLevel':" with options (Node2D, Node3D, Control, Node)
- ✅ Follow-up required: "Create a 2D scene called 'TestLevel' with Node2D root"
- ✅ Message: "Scene 'TestLevel' created successfully at res://scenes/TestLevel.tscn with Node2D root node"
- ✅ Scene opens in Godot editor with Node2D root
- ✅ File appears in Godot FileSystem dock

### Test: Create Scene with Specified Root Type
**Prompt:** `Create a 3D scene called "WorldLevel" with Node3D root`

**Expected Outcome:**
- ✅ Message: "Scene 'WorldLevel' created successfully at res://scenes/WorldLevel.tscn with Node3D root node"
- ✅ Scene opens in Godot editor with Node3D root
- ✅ File appears in Godot FileSystem dock

### Test: Create Scene with Custom Path (Directory Creation)
**Prompt:** `Create a scene named "MainMenu" at the path "res://ui/MainMenu.tscn"`

**Expected Outcome:**
- ✅ Prompt for root node type first (if not specified)
- ✅ Directory existence check: "Directory 'res://ui/' doesn't exist for scene 'MainMenu.tscn'. Would you like me to: Create the directory and proceed..."
- ✅ Follow-up required: "Create a Control scene called 'MainMenu' at 'res://ui/MainMenu.tscn' and create directories"
- ✅ Message: "Scene 'MainMenu' created successfully at res://ui/MainMenu.tscn with Control root node (created directory: res://ui)"
- ✅ `ui/` directory created automatically
- ✅ Scene opens in Godot editor

### Test: Create Scene with Deep Directory Path
**Prompt:** `Create a Node2D scene called "Boss" at "res://levels/world1/bosses/Boss.tscn" and create directories`

**Expected Outcome:**
- ✅ Message: "Scene 'Boss' created successfully at res://levels/world1/bosses/Boss.tscn with Node2D root node (created directory: res://levels/world1/bosses)"
- ✅ Nested directory structure created automatically
- ✅ Scene opens in Godot editor

### Test: Get Current Scene (With Scene Open)
**Prompt:** `What scene is currently open now?`

**Expected Outcome:**
- ✅ Scene name, path, correct root node type (Node2D, Node3D, etc.), and child count displayed
- ✅ Should match the scene you just created

### Test: Open Existing Scene
**Prompt:** `Open the scene at "res://scenes/TestLevel.tscn"`

**Expected Outcome:**
- ✅ Message: "Scene opened successfully: res://scenes/TestLevel.tscn"
- ✅ Scene switches in Godot editor

### Test: List All Scenes ✨ NEW
**Prompt:** `List all scenes in the project`

**Expected Outcome:**
- ✅ Message: "Found X scene(s) in the project:" followed by list
- ✅ Each scene shows name, path, and directory
- ✅ Includes previously created scenes (TestLevel, WorldLevel, MainMenu, etc.)

### Test: Duplicate Scene ✨ NEW
**Prompt:** `Duplicate the scene at "res://scenes/TestLevel.tscn" with the name "TestLevelCopy"`

**Expected Outcome:**
- ✅ Message: "Scene duplicated successfully from res://scenes/TestLevel.tscn to res://scenes/TestLevelCopy.tscn"
- ✅ New scene file appears in Godot FileSystem dock
- ✅ Copy contains same content as original

### Test: Delete Scene ✨ NEW
**Prompt:** `Delete the scene at "res://scenes/TestLevelCopy.tscn" with confirmation`

**Expected Outcome:**
- ✅ Message: "Scene deleted successfully: res://scenes/TestLevelCopy.tscn"
- ✅ Scene file removed from Godot FileSystem dock
- ✅ File no longer exists in project

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

### Test: Delete Node ✨ NEW
**Prompt:** `Delete the node "GameTimer" from the scene with confirmation`

**Expected Outcome:**
- ✅ Message: "Node deleted successfully: GameTimer"
- ✅ Node removed from Scene dock
- ✅ Node no longer visible in scene hierarchy

### Test: Move Node ✨ NEW
**Prompt:** `Move the "PlayerSprite" node to be a child of "StartButton"`

**Expected Outcome:**
- ✅ Message: "Node 'PlayerSprite' moved successfully to parent 'StartButton'"
- ✅ Node hierarchy updated in Scene dock
- ✅ PlayerSprite now appears under StartButton

### Test: Get Node Properties ✨ NEW
**Prompt:** `Get the properties of the "StartButton" node`

**Expected Outcome:**
- ✅ Message: "Properties of node 'StartButton' (type: Button):" followed by property list
- ✅ Shows accessible properties like text, position, size, etc.
- ✅ Properties display with current values

### Test: Set Node Properties ✨ NEW
**Prompt:** `Set the properties of "StartButton": text to "Start Game", position to (100, 50)`

**Expected Outcome:**
- ✅ Message: "Node 'StartButton' properties updated" with success/failure details
- ✅ Button text changes to "Start Game" in Godot editor
- ✅ Button position updates to specified coordinates

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

### Test: List All Scripts ✨ NEW
**Prompt:** `List all scripts in the project`

**Expected Outcome:**
- ✅ Message: "Found X script(s) in the project:" followed by list
- ✅ Each script shows name, path, and directory
- ✅ Includes previously created scripts (player.gd, ui.gd, game_manager.gd, etc.)

### Test: Read Script Content ✨ NEW
**Prompt:** `Read the content of the script at "res://scripts/game_manager.gd"`

**Expected Outcome:**
- ✅ Message: "Content of script 'res://scripts/game_manager.gd':" followed by formatted code
- ✅ Shows complete script content in code block format
- ✅ Content matches what was written to the file

### Test: Modify Script Content ✨ NEW
**Prompt:** `Modify the script at "res://scripts/game_manager.gd" to add a reset_score function`

**Expected Outcome:**
- ✅ Message: "Script modified successfully: res://scripts/game_manager.gd"
- ✅ Script content updated in Godot script editor
- ✅ New function visible when reopening the script

### Test: Delete Script ✨ NEW
**Prompt:** `Delete the script at "res://scripts/game_manager.gd" with confirmation`

**Expected Outcome:**
- ✅ Message: "Script deleted successfully: res://scripts/game_manager.gd"
- ✅ Script file removed from Godot FileSystem dock
- ✅ File no longer exists in project

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

### Test: Advanced Node Management Workflow ✨ NEW
**Prompt:** `In the current scene, move all UI elements under a new Control node called "UI", then set the UI node's position to (0, 0)`

**Expected Outcome:**
- ✅ Control node "UI" created successfully
- ✅ All UI nodes (StartButton, ScoreLabel, etc.) moved under UI
- ✅ UI node position set to (0, 0)
- ✅ Scene hierarchy properly organized

### Test: Script Management Workflow ✨ NEW
**Prompt:** `List all scripts, read the player script, modify it to add a jump function, then create a backup copy`

**Expected Outcome:**
- ✅ All scripts listed showing current project scripts
- ✅ Player script content displayed
- ✅ Script modified with new jump function
- ✅ Backup script created (if using duplicate scene for script backups)

### Test: Project Organization Workflow ✨ NEW
**Prompt:** `List all scenes and scripts in the project, then organize them by creating appropriate folders`

**Expected Outcome:**
- ✅ Complete inventory of scenes and scripts displayed
- ✅ Clear overview of project structure
- ✅ Ability to plan reorganization based on current files

---

## 🎯 **5. UI Control & Positioning Tests** 🆕 PHASE 3

### Test: Set Control Anchors
**Prompt:** `Set the anchors for the "StartButton" node: left=0.5, top=0.5, right=0.5, bottom=0.5`

**Expected Outcome:**
- ✅ Message: "Control anchors set for node 'StartButton': left=0.5, top=0.5, right=0.5, bottom=0.5"
- ✅ Button anchored to center point in Godot editor
- ✅ Anchor handles show center positioning in Scene view

### Test: Center Control Node
**Prompt:** `Center the "ScoreLabel" node both horizontally and vertically`

**Expected Outcome:**
- ✅ Message: "Control node 'ScoreLabel' centered horizontally and vertically"
- ✅ Label positioned at exact center of parent in Godot editor
- ✅ Fixes top-left clustering issue mentioned in roadmap

### Test: Position Control with Anchor Preset
**Prompt:** `Position the "StartButton" at coordinates (100, 50) with top_left anchor preset`

**Expected Outcome:**
- ✅ Message: "Control node 'StartButton' positioned at (100, 50) with top_left anchor preset"
- ✅ Button positioned at specified coordinates from top-left
- ✅ Anchor preset applied correctly

### Test: Fit Control to Parent
**Prompt:** `Make the "UI" node fill its parent container with 10 pixel margin`

**Expected Outcome:**
- ✅ Message: "Control node 'UI' fitted to parent with 10px margin"
- ✅ UI node fills entire parent with 10px border all around
- ✅ Anchors set to full rect (0,0,1,1) with proper offsets

### Test: Set Anchor Margins
**Prompt:** `Set margins for "StartButton": left=20, top=30, right=120, bottom=80`

**Expected Outcome:**
- ✅ Message: "Anchor margins set for node 'StartButton': left=20, top=30, right=120, bottom=80"
- ✅ Button positioned with precise pixel margins from anchors
- ✅ Margins visible in Godot Inspector

### Test: Configure Size Flags
**Prompt:** `Configure "StartButton" size flags: horizontal=['fill', 'expand'], vertical=['shrink_center']`

**Expected Outcome:**
- ✅ Message: "Size flags configured for node 'StartButton' - Horizontal: fill, expand - Vertical: shrink_center"
- ✅ Button behaves correctly in container layouts
- ✅ Size flags reflected in Godot Inspector

### Test: Setup Complete Control Rect
**Prompt:** `Setup control rect for "StartButton": position (50, 25), size (200, 40), with center anchor preset`

**Expected Outcome:**
- ✅ Message: "Control rect set for node 'StartButton': position=(50, 25), size=(200, 40) with center anchor preset"
- ✅ Button positioned and sized precisely
- ✅ Anchor preset applied before positioning

### Test: UI Layout Workflow
**Prompt:** `Create a centered main menu: center the "UI" node, then position "StartButton" at (0, -50) and "QuitButton" at (0, 50) relative to center`

**Expected Outcome:**
- ✅ UI node centered in parent
- ✅ Buttons positioned above and below center
- ✅ Clean, professional menu layout
- ✅ All positioning operations successful

### Test: Container Layout with Size Flags
**Prompt:** `Add a VBoxContainer called "MenuContainer", set its size flags to fill and expand both directions, then move all buttons into it`

**Expected Outcome:**
- ✅ VBoxContainer created with proper size flags
- ✅ Buttons moved into container
- ✅ Container fills available space
- ✅ Vertical layout applied to child buttons

---

## 💎 **6. Asset Management Tests** 🆕 PHASE 2

### Test: Import Image Asset
**Prompt:** `Import the image file at "/Users/username/Desktop/player_sprite.png" as an image asset`

**Expected Outcome:**
- ✅ Message: "Asset imported successfully from /Users/username/Desktop/player_sprite.png to res://textures/player_sprite.png"
- ✅ File appears in Godot FileSystem dock under textures/ directory
- ✅ Asset automatically reimported in Godot editor

### Test: Import Audio Asset with Custom Path
**Prompt:** `Import the audio file at "/Users/username/Downloads/music.ogg" to "res://audio/background/music.ogg" as an audio asset`

**Expected Outcome:**
- ✅ Message: "Asset imported successfully from /Users/username/Downloads/music.ogg to res://audio/background/music.ogg"
- ✅ Directory structure created automatically (audio/background/)
- ✅ File appears in correct location in FileSystem dock

### Test: List All Resources
**Prompt:** `List all resources in the project`

**Expected Outcome:**
- ✅ Message: "Found X resource(s) in res://:" followed by detailed list
- ✅ Each resource shows name, path, directory, size, type, and extension
- ✅ Includes all assets: scenes (.tscn), scripts (.gd), textures (.png, .jpg), audio (.ogg, .wav), etc.
- ✅ Proper file size display (e.g., "2048 bytes", "15.2 KB")

### Test: List Resources with Filtering
**Prompt:** `List all image resources in the textures directory`

**Expected Outcome:**
- ✅ Message showing filtered results for textures/ directory
- ✅ Only image files displayed (.png, .jpg, .jpeg, .bmp, .tga, .webp)
- ✅ Correct type classification as "image"

### Test: Organize Assets
**Prompt:** `Move the file "res://player_sprite.png" to "res://characters/player/sprite.png" and update references`

**Expected Outcome:**
- ✅ Message: "Asset organized successfully from res://player_sprite.png to res://characters/player/sprite.png"
- ✅ Directory structure created (characters/player/)
- ✅ File moved to new location in FileSystem dock
- ✅ Reference update count reported (if any references exist)

### Test: List Resources by Type
**Prompt:** `List all audio files in the project`

**Expected Outcome:**
- ✅ Filtered list showing only audio assets
- ✅ Files show as type "audio" with proper extensions (.ogg, .wav, .mp3)
- ✅ Recursive scanning includes audio files in subdirectories

---

## 🔧 **7. Project Management Tests** 🆕 PHASE 2

### Test: Get All Project Settings
**Prompt:** `Get all project settings`

**Expected Outcome:**
- ✅ Message: "All project settings retrieved" followed by comprehensive list
- ✅ Settings organized by categories (application/, rendering/, input/, etc.)
- ✅ Each setting shows full path and current value
- ✅ Includes core settings like application/config/name, application/config/version

### Test: Get Specific Project Setting
**Prompt:** `Get the project setting for "application/config/name"`

**Expected Outcome:**
- ✅ Message: "Project setting retrieved: application/config/name: [ProjectName]"
- ✅ Shows current project name value
- ✅ Clean, focused output for single setting

### Test: Modify Project Setting
**Prompt:** `Set the project setting "application/config/name" to "MyAwesomeGame"`

**Expected Outcome:**
- ✅ Message: "Project setting updated successfully: application/config/name: MyAwesomeGame"
- ✅ Project name changed in Godot Project Settings
- ✅ project.godot file updated automatically

### Test: Create New Project Setting
**Prompt:** `Create a new project setting "custom/game/difficulty" with value "normal" and allow creation if missing`

**Expected Outcome:**
- ✅ Message: "Project setting updated successfully: custom/game/difficulty: normal"
- ✅ New setting visible in Godot Project Settings under custom category
- ✅ Setting persisted in project.godot file

### Test: List Export Presets
**Prompt:** `Show available export presets for the project`

**Expected Outcome:**
- ✅ Message: "Available export presets:" followed by preset list
- ✅ Shows all configured export presets (e.g., "Windows Desktop", "Linux", "Android")
- ✅ Clear indication if no presets are configured

### Test: Export Project (if presets available)
**Prompt:** `Export the project using the "Windows Desktop" preset to "/Users/username/Desktop/MyGame.exe"`

**Expected Outcome:**
- ✅ Message: "Export initiated (Note: Full export implementation requires editor plugin integration)"
- ✅ Shows preset name, output path, and debug mode settings
- ✅ Framework validates preset exists and paths are valid

---

## ⚠️ **8. Error Handling Tests**

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

### Test: Delete Non-existent Scene ✨ NEW
**Prompt:** `Delete the scene at "res://nonexistent/scene.tscn" with confirmation`

**Expected Outcome:**
- ✅ Error message: "Scene file not found: res://nonexistent/scene.tscn"
- ✅ No files affected

### Test: Delete Node Without Confirmation ✨ NEW
**Prompt:** `Delete the node "StartButton" from the scene`

**Expected Outcome:**
- ✅ Error message: "Deletion requires confirmation. Set confirm=true to proceed."
- ✅ Node remains in scene unchanged

### Test: Move Non-existent Node ✨ NEW
**Prompt:** `Move the "NonExistentNode" to be a child of "Player"`

**Expected Outcome:**
- ✅ Error message: "Node not found: NonExistentNode"
- ✅ Scene hierarchy unchanged

### Test: Read Non-existent Script ✨ NEW
**Prompt:** `Read the content of the script at "res://scripts/nonexistent.gd"`

**Expected Outcome:**
- ✅ Error message: "Script file not found: res://scripts/nonexistent.gd"
- ✅ No content displayed

### Test: Import Non-existent Asset 🆕 PHASE 2
**Prompt:** `Import the image file at "/Users/username/Desktop/nonexistent.png" as an image asset`

**Expected Outcome:**
- ✅ Error message: "Source file not found: /Users/username/Desktop/nonexistent.png"
- ✅ No file operations performed

### Test: Organize Non-existent Asset 🆕 PHASE 2
**Prompt:** `Move the file "res://nonexistent.png" to "res://textures/moved.png"`

**Expected Outcome:**
- ✅ Error message: "Source file not found: res://nonexistent.png"
- ✅ No file operations performed

### Test: Get Non-existent Project Setting 🆕 PHASE 2
**Prompt:** `Get the project setting for "nonexistent/fake/setting"`

**Expected Outcome:**
- ✅ Error message: "Project setting not found: nonexistent/fake/setting"
- ✅ No setting value displayed

### Test: Modify Project Setting Without Permission 🆕 PHASE 2
**Prompt:** `Set the project setting "nonexistent/fake/setting" to "test" without creating if missing`

**Expected Outcome:**
- ✅ Error message: "Project setting not found: nonexistent/fake/setting. Set create_if_missing=true to create it."
- ✅ No setting created or modified

### Test: Set Anchors on Non-Control Node 🆕 PHASE 3
**Prompt:** `Set anchors for the "Player" node (which is a Node2D): left=0.5, top=0.5, right=0.5, bottom=0.5`

**Expected Outcome:**
- ✅ Error message: "Node is not a Control node: Player"
- ✅ No anchor changes applied

### Test: Center Non-existent Control Node 🆕 PHASE 3
**Prompt:** `Center the "NonExistentUI" node both horizontally and vertically`

**Expected Outcome:**
- ✅ Error message: "Node not found: NonExistentUI"
- ✅ No positioning changes applied

### Test: Position Control with Invalid Anchor Preset 🆕 PHASE 3
**Prompt:** `Position the "StartButton" at (100, 50) with invalid_preset anchor preset`

**Expected Outcome:**
- ✅ Button positioned correctly (invalid preset ignored)
- ✅ Warning or note that invalid preset was not applied
- ✅ Position still set as requested

### Test: Create Centered UI Element 🆕 SMART UI
**Prompt:** `Create a centered Label called "GameTitle" with text "Epic Adventure" and size 300x50`

**Expected Outcome:**
- ✅ Message: "Centered UI element 'GameTitle' of type 'Label' created successfully with size 300x50"
- ✅ Label appears perfectly centered in parent container in Godot editor
- ✅ Text "Epic Adventure" is set automatically
- ✅ Anchors set to center (0.5, 0.5, 0.5, 0.5) with proper offsets

### Test: Create Fullscreen UI Element 🆕 SMART UI
**Prompt:** `Create a fullscreen Panel called "Background" with 10 pixel margins`

**Expected Outcome:**
- ✅ Message: "Fullscreen UI element 'Background' of type 'Panel' created successfully with 10px margin"
- ✅ Panel fills entire parent container minus 10px margins
- ✅ Anchors set to full rect (0, 0, 1, 1) with margin offsets
- ✅ Proper background panel for overlays

### Test: Setup UI Container with Children 🆕 SMART UI
**Prompt:** `Create a centered VBoxContainer called "MainMenu" with children: Button "StartGame" with text "Start Game", Button "Settings" with text "Settings", Button "Quit" with text "Quit"`

**Expected Outcome:**
- ✅ Message: "Container 'MainMenu' created with 3 children: StartGame, Settings, Quit"
- ✅ VBoxContainer positioned at center of parent
- ✅ Three buttons created as children with correct text
- ✅ Vertical layout applied with proper spacing
- ✅ All elements properly centered and organized

### Test: Apply Common UI Pattern - Main Menu 🆕 SMART UI
**Prompt:** `Apply the main_menu UI pattern with title "Epic Adventure" and buttons ["Start Game", "Load Game", "Settings", "Quit"]`

**Expected Outcome:**
- ✅ Message: "UI pattern 'main_menu' applied successfully. Created nodes: main_menu_Title, main_menu_StartGame, main_menu_LoadGame, main_menu_Settings, main_menu_Quit, main_menu_Container"
- ✅ Professional main menu layout created instantly
- ✅ Title label "Epic Adventure" centered at top
- ✅ Four buttons with specified text in vertical layout
- ✅ Container properly centered with good spacing

### Test: Apply Common UI Pattern - HUD 🆕 SMART UI
**Prompt:** `Apply the hud UI pattern for the game interface`

**Expected Outcome:**
- ✅ Message: "UI pattern 'hud' applied successfully. Created nodes: hud_HUD, hud_HealthContainer, hud_HealthLabel, hud_Score"
- ✅ Full-screen HUD overlay created
- ✅ Health container in top-left with "Health: " label
- ✅ Score label in top-right showing "Score: 0"
- ✅ Elements positioned correctly for game HUD

### Test: Apply Common UI Pattern - Dialog 🆕 SMART UI
**Prompt:** `Apply the dialog UI pattern with title "Confirm Exit" at the root level`

**Expected Outcome:**
- ✅ Message: "UI pattern 'dialog' applied successfully. Created nodes: dialog_Panel, dialog_Content, dialog_Title, dialog_OK"
- ✅ Centered dialog panel created over current content
- ✅ "Confirm Exit" title displayed prominently
- ✅ OK button ready for user interaction
- ✅ Professional dialog layout with proper margins

### Test: Create Smart UI Combined Workflow 🆕 SMART UI
**Prompt:** `Create a fullscreen background panel, then add a centered main menu using the main_menu pattern with title "My Game"`

**Expected Outcome:**
- ✅ Fullscreen background panel created first
- ✅ Main menu pattern applied on top with proper hierarchy
- ✅ Both elements properly positioned and functional
- ✅ Complete professional menu system ready for use

---

## 🎯 **9. UI Layout Management Tests** 🆕 PHASE 3 UI LAYOUT

### Test: Create UI Layout Container 🆕 UI LAYOUT
**Prompt:** `Create a VBoxContainer called "MainLayout" with centered positioning and 300x400 size`

**Expected Outcome:**
- ✅ Message: "UI layout container 'MainLayout' of type 'VBoxContainer' created successfully with centered positioning"
- ✅ VBoxContainer appears in Godot Scene dock
- ✅ Container is properly centered in parent with specified size
- ✅ Container positioned with correct anchors (0.5, 0.5, 0.5, 0.5)

### Test: Create GridContainer with Custom Configuration 🆕 UI LAYOUT
**Prompt:** `Create a GridContainer called "InventoryGrid" with fullscreen positioning, 4 columns, and spacing of 10`

**Expected Outcome:**
- ✅ Message: "UI layout container 'InventoryGrid' of type 'GridContainer' created successfully with fullscreen positioning"
- ✅ GridContainer fills entire parent with proper anchors (0, 0, 1, 1)
- ✅ Container configured with 4 columns
- ✅ Grid layout ready for child elements

### Test: Create Custom Positioned Container 🆕 UI LAYOUT
**Prompt:** `Create an HSplitContainer called "SplitView" with custom positioning at (50, 100) and size 600x300`

**Expected Outcome:**
- ✅ HSplitContainer created with specified position and size
- ✅ Container positioned exactly at (50, 100) coordinates
- ✅ Size set to 600x300 pixels
- ✅ Split container ready for resizable sections

### Test: Set Anchor Preset 🆕 UI LAYOUT
**Prompt:** `Set the anchor preset for "MainLayout" to "full_rect" keeping current offsets`

**Expected Outcome:**
- ✅ Message: "Anchor preset 'full_rect' applied to node 'MainLayout'"
- ✅ Container anchors changed to full rect (0, 0, 1, 1)
- ✅ Original size and position preserved due to keep_offsets option
- ✅ Container now fills parent completely

### Test: Apply Center Anchor Preset 🆕 UI LAYOUT
**Prompt:** `Set the anchor preset for "InventoryGrid" to "center" without keeping offsets`

**Expected Outcome:**
- ✅ Message: "Anchor preset 'center' applied to node 'InventoryGrid'"
- ✅ Container anchors set to center point (0.5, 0.5, 0.5, 0.5)
- ✅ Container repositioned to center of parent
- ✅ Size and position adjusted to new anchor configuration

### Test: Align Multiple Controls 🆕 UI LAYOUT
**Prompt:** `Align these controls to the left: ["Button1", "Button2", "Button3"] using the first button as reference`

**Expected Outcome:**
- ✅ Message: "Aligned 3 controls with 'left' alignment using 'first' reference"
- ✅ All three buttons aligned to same left position
- ✅ First button position used as reference point
- ✅ Vertical positions remain unchanged

### Test: Center Align Multiple Controls 🆕 UI LAYOUT
**Prompt:** `Align these UI elements to center horizontally: ["StartButton", "SettingsButton", "QuitButton"] using parent as reference`

**Expected Outcome:**
- ✅ Message: "Aligned 3 controls with 'center_horizontal' alignment using 'parent' reference"
- ✅ All buttons centered horizontally within parent bounds
- ✅ Parent container used as reference for centering calculation
- ✅ Buttons maintain individual vertical positions

### Test: Distribute Controls Horizontally 🆕 UI LAYOUT
**Prompt:** `Distribute these controls horizontally with 20 pixel spacing: ["Button1", "Button2", "Button3", "Button4"]`

**Expected Outcome:**
- ✅ Message: "Distributed 4 controls horizontally with spacing of 20"
- ✅ All four buttons distributed with exactly 20 pixels between them
- ✅ Horizontal positions calculated with proper spacing
- ✅ Vertical positions remain unchanged

### Test: Even Distribution Vertically 🆕 UI LAYOUT
**Prompt:** `Distribute these labels vertically with even spacing: ["Title", "Subtitle", "Description", "Footer"]`

**Expected Outcome:**
- ✅ Message: "Distributed 4 controls vertically with spacing of [calculated]"
- ✅ Labels distributed evenly across available vertical space
- ✅ Automatic spacing calculation between elements
- ✅ Professional vertical layout achieved

### Test: Distribution with Custom Bounds 🆕 UI LAYOUT
**Prompt:** `Distribute these buttons horizontally from position 100 to 800: ["First", "Second", "Third"]`

**Expected Outcome:**
- ✅ Message: "Distributed 3 controls horizontally with spacing of [calculated]"
- ✅ First button positioned at x=100
- ✅ Last button positioned so it ends at x=800
- ✅ Middle button evenly spaced between boundaries

### Test: Complex Layout Workflow 🆕 UI LAYOUT
**Prompt:** `Create a VBoxContainer called "MenuContainer" with centered positioning, then create 3 buttons inside it, align them center, and distribute them vertically with 15 pixel spacing`

**Expected Outcome:**
- ✅ VBoxContainer created and centered
- ✅ Three buttons created inside container
- ✅ Buttons aligned to center horizontally
- ✅ Buttons distributed vertically with 15px spacing
- ✅ Professional menu layout achieved

### Test: Layout Management Error Cases 🆕 UI LAYOUT

#### Test: Invalid Container Type
**Prompt:** `Create a FakeContainer called "BadContainer" with centered positioning`

**Expected Outcome:**
- ✅ Error message: "Invalid container type: FakeContainer"
- ✅ No container created in scene

#### Test: Insufficient Nodes for Alignment
**Prompt:** `Align these controls to the left: ["OnlyButton"]`

**Expected Outcome:**
- ✅ Error message: "At least 2 nodes are required for alignment"
- ✅ No alignment operations performed

#### Test: Invalid Anchor Preset
**Prompt:** `Set the anchor preset for "MainLayout" to "invalid_preset"`

**Expected Outcome:**
- ✅ Anchor preset function executes (invalid preset ignored)
- ✅ No error but no anchor changes applied
- ✅ Original anchor configuration preserved

#### Test: Distribution with Too Few Nodes
**Prompt:** `Distribute these controls horizontally: ["Button1", "Button2"]`

**Expected Outcome:**
- ✅ Error message: "At least 3 nodes are required for distribution"
- ✅ No distribution operations performed

#### Test: Align Non-Control Nodes
**Prompt:** `Align these nodes to the left: ["Player", "Enemy"] where Player is a Node2D`

**Expected Outcome:**
- ✅ Error message: "Node is not a Control node: Player"
- ✅ No alignment operations performed

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
- `Set up a main menu scene with start and quit buttons in the ui folder`
- `Create a simple enemy with basic AI behavior script in the enemies directory`
- `Build a collectible item with pickup functionality in a dedicated items folder`

### Advanced Combinations
- `Create a game manager that tracks score and handles level transitions`
- `Set up a player health system with UI display in the ui/hud directory`
- `Create a dialogue system with text display and progression in ui/dialogue`
- `Build a simple inventory system for a 2D game in systems/inventory`

### Project Organization ✨ ENHANCED
- `List all scenes and scripts to see my current project structure`
- `Organize my project: create 2D scenes for player, enemies, and UI in separate folders`
- `Set up a clean project structure for a puzzle game with levels in levels/ and UI in ui/`
- `Create template 3D scenes for different game object types in templates/3d/`
- `Build a UI scene for settings menu at ui/menus/SettingsMenu.tscn and create directories`

### Debugging & Inspection ✨ ENHANCED
- `Show me the current scene structure and all nodes`
- `List all scripts in my project and what they're attached to`
- `Get the properties of the Player node to see its current settings`
- `Check if there are any scenes without proper node hierarchies`
- `Read the content of my main player script to review the code`

### Asset Management ✨ ENHANCED
- `Duplicate my MainLevel scene to create a TestLevel for experimentation`
- `Create a backup of my player script before making major changes`
- `Delete old prototype scenes that are no longer needed`
- `Move all UI elements under a parent UI node for better organization`
- `Import my sprite assets from Desktop into the project with proper organization` 🆕 PHASE 2
- `List all resources in the project to see what assets I have` 🆕 PHASE 2
- `Organize my texture files into character/, environment/, and ui/ folders` 🆕 PHASE 2

### Code Management ✨ NEW
- `Show me all the scripts in my project and their locations`
- `Read my player controller script and suggest improvements`
- `Modify my game manager script to add a pause function`
- `Create a new enemy AI script based on my existing player script`

### Scene Restructuring ✨ NEW
- `Move the HUD elements to be children of a new UI node`
- `Reorganize my scene hierarchy to group related objects`
- `Set the player's spawn position to (100, 200) using node properties`
- `Duplicate my enemy scene and modify it for a boss variant`

### Project Configuration 🆕 PHASE 2
- `Show me all my project settings to review the current configuration`
- `Change the project name to "My Epic Adventure Game"`
- `Set up custom project settings for my game's difficulty levels`
- `Configure the project for mobile export with proper settings`
- `Check what export presets are available for my project`

### Advanced Asset Workflows 🆕 PHASE 2
- `Import all my character sprites from a folder and organize them properly`
- `List all audio files to see what sounds I have in the project`
- `Reorganize my assets: move UI textures to ui/, character sprites to characters/`
- `Import background music and place it in audio/music/ directory`
- `Create a clean asset structure for a 2D platformer with organized folders`

### UI Control & Positioning 🆕 PHASE 3
- `Create a main menu with properly centered buttons that don't cluster in the top-left`
- `Set up a HUD with a health bar in the top-left and score display in the top-right`
- `Center the game over dialog both horizontally and vertically on screen`
- `Make the pause menu fill the entire screen with a semi-transparent background`
- `Position the inventory panel at the bottom-right corner with proper margins`
- `Create a settings menu with controls that expand to fill their container`
- `Set up a loading screen with a centered progress bar and status text`
- `Design a mobile UI that adapts properly to different screen sizes using anchors`
- `Build a split-screen UI with left and right panels that resize proportionally`
- `Create a game HUD with anchored elements that stay in position during screen resize`

### Smart UI Creation Helpers 🆕 PHASE 3 SMART UI
- `Create a centered "Start Game" button with 200x50 size that's automatically positioned in the middle`
- `Create a fullscreen background panel for the main menu with 20 pixel margins`
- `Set up a main menu container with title and three buttons: "Start Game", "Settings", "Quit"`
- `Apply the main_menu UI pattern with custom title "Epic Adventure" and buttons`
- `Create a game HUD using the hud pattern with health and score displays`
- `Set up a pause dialog using the dialog pattern with title "Game Paused"`
- `Create a centered VBox container with three labels showing game stats`
- `Make a fullscreen ColorRect background for the loading screen`
- `Apply the button_row pattern with "Easy", "Medium", "Hard" difficulty buttons`
- `Create a centered settings panel with a container holding various UI controls`

### UI Layout Management 🆕 PHASE 3 UI LAYOUT
- `Create a GridContainer called "InventoryGrid" with fullscreen positioning and 6 columns for an item grid`
- `Set up an HSplitContainer called "GameLayout" with custom positioning to create resizable game panels`
- `Apply the full_rect anchor preset to the background panel to make it fill the entire screen`
- `Align all the menu buttons to center horizontally using the parent container as reference`
- `Distribute the difficulty selection buttons horizontally with 30 pixel spacing between them`
- `Create a VBoxContainer for the settings menu, then align all option labels to the left`
- `Set up a responsive layout: create a TabContainer with fullscreen positioning for multiple game panels`
- `Distribute the HUD elements vertically across the left side of the screen with even spacing`
- `Apply center anchor preset to the dialog box and align all its buttons horizontally`
- `Create a complex menu layout: VBoxContainer with centered positioning, add buttons, align center, distribute vertically`

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