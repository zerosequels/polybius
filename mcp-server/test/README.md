# MCP Server Unit Tests

This directory contains comprehensive unit tests for the Polybius MCP Server components.

## Test Structure

```
test/
├── __init__.py                    # Python package marker
├── README.md                      # This file
├── run_tests.py                   # Test runner script
├── test_godot_client.py          # Tests for GodotClient HTTP functionality
├── test_tool_registration.py     # Tests for MCP tool registration and schemas
├── test_scene_tools.py           # Tests for scene management tools
└── test_script_tools.py          # Tests for script creation tools
```

## Running Tests

### Prerequisites

Install test dependencies:
```bash
cd mcp-server
pip install pytest pytest-asyncio
```

### Run All Tests
```bash
# From the mcp-server directory
python test/run_tests.py

# Or using pytest directly
python -m pytest test/ --asyncio-mode=auto -v
```

### Run Individual Test Suites
```bash
# Run specific test file
python test/run_tests.py godot_client
python test/run_tests.py tool_registration
python test/run_tests.py scene_tools
python test/run_tests.py script_tools

# Or using pytest directly
python -m pytest test/test_godot_client.py -v
```

## Test Coverage

### GodotClient Tests (`test_godot_client.py`)
- HTTP client initialization and configuration
- Health check endpoint communication
- Scene creation, opening, and querying
- Node addition to scenes
- Script creation and attachment
- Error handling for network failures
- Mock-based testing without requiring Godot

### Tool Registration Tests (`test_tool_registration.py`)
- MCP tool registration and listing
- Tool schema validation
- Tool description quality checks
- Health check tool functionality
- Unknown tool handling

### Scene Tools Tests (`test_scene_tools.py`)
- Scene creation with and without custom paths
- Scene opening and error handling
- Current scene information retrieval
- Node addition with parent paths
- Tool argument validation
- Success and failure response handling

### Script Tools Tests (`test_script_tools.py`)
- Script creation with custom content
- Script attachment to nodes
- Path validation and error handling
- Optional parameter handling
- GDScript-specific functionality

## Test Philosophy

### Unit Tests (Current)
- **Isolated**: Each component tested independently with mocks
- **Fast**: No external dependencies or network calls
- **Comprehensive**: Cover success, failure, and edge cases
- **Maintainable**: Clear test names and structure

### Integration Tests (Separate)
- Require running Godot editor with claude_mcp plugin
- Test actual HTTP communication
- Validate end-to-end MCP protocol flow
- See main testing plan for integration test procedures

## Adding New Tests

When adding new MCP tools or modifying existing ones:

1. **Update relevant test file** or create new one following naming convention
2. **Test both success and failure cases**
3. **Validate input schemas** and parameter handling
4. **Use mocks** for external dependencies (GodotClient, HTTP calls)
5. **Follow existing test patterns** for consistency

## Troubleshooting

### Common Issues

**ImportError for src modules:**
- Ensure you run tests from the `mcp-server` directory
- The test runner automatically adds the project root to Python path

**Async test failures:**
- Install `pytest-asyncio`: `pip install pytest-asyncio`
- Tests use `@pytest.mark.asyncio` decorator

**Mock assertion failures:**
- Check that mock calls match expected parameters exactly
- Use `mock_obj.assert_called_once_with(expected_args)` for verification

### Test Development Tips

```python
# Example test structure
@pytest.mark.asyncio
async def test_feature_success(self, mock_client):
    # Arrange
    mock_client.method.return_value = {"success": True}
    
    # Act  
    result = await handle_tool("tool_name", {"arg": "value"}, mock_client)
    
    # Assert
    mock_client.method.assert_called_once_with("value")
    assert "expected text" in result[0].text
```

Run tests frequently during development to catch regressions early.