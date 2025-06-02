#!/usr/bin/env python3
"""
Test runner for the Polybius MCP Server

This script runs all unit tests for the MCP server components.
Use this to validate the MCP server before integration testing.
"""

import sys
import os
import subprocess
from pathlib import Path

def main():
    """Run all unit tests for the MCP server"""
    # Get the project root directory
    project_root = Path(__file__).parent.parent
    
    # Add the project root to Python path so we can import src modules
    sys.path.insert(0, str(project_root))
    
    # Change to project root directory
    os.chdir(project_root)
    
    print("🧪 Running Polybius MCP Server Unit Tests")
    print("=" * 50)
    
    # Check if pytest is available
    try:
        import pytest
    except ImportError:
        print("❌ Error: pytest is required to run tests")
        print("Install dependencies with: pip install -r requirements.txt")
        return 1
    
    # Check if pytest-asyncio is available
    try:
        import pytest_asyncio
    except ImportError:
        print("❌ Error: pytest-asyncio is required for async tests")
        print("Install dependencies with: pip install -r requirements.txt")
        return 1
    
    # Define test files to run
    test_files = [
        "test/test_godot_client.py",
        "test/test_tool_registration.py", 
        "test/test_scene_tools.py",
        "test/test_script_tools.py"
    ]
    
    # Check that all test files exist
    missing_files = []
    for test_file in test_files:
        if not Path(test_file).exists():
            missing_files.append(test_file)
    
    if missing_files:
        print(f"❌ Error: Missing test files: {', '.join(missing_files)}")
        return 1
    
    print(f"📋 Running {len(test_files)} test suites...")
    print()
    
    # Run pytest with verbose output
    cmd = [
        sys.executable, "-m", "pytest",
        "--verbose",
        "--tb=short",
        "--asyncio-mode=auto",
        *test_files
    ]
    
    try:
        result = subprocess.run(cmd, check=False)
        
        if result.returncode == 0:
            print()
            print("✅ All tests passed!")
            print()
            print("🚀 Next steps:")
            print("1. Ensure Godot editor with the claude_mcp plugin is running")
            print("2. Run integration tests by calling individual MCP tools")
            print("3. Test the full MCP protocol with Claude Desktop")
            return 0
        else:
            print()
            print("❌ Some tests failed!")
            print("Review the output above to fix failing tests")
            return result.returncode
            
    except KeyboardInterrupt:
        print("\n⚠️  Tests interrupted by user")
        return 1
    except Exception as e:
        print(f"❌ Error running tests: {e}")
        return 1


def run_individual_test(test_name):
    """Run a specific test file"""
    project_root = Path(__file__).parent.parent
    sys.path.insert(0, str(project_root))
    os.chdir(project_root)
    
    test_file = f"test/{test_name}"
    if not Path(test_file).exists():
        print(f"❌ Test file not found: {test_file}")
        return 1
    
    cmd = [
        sys.executable, "-m", "pytest",
        "--verbose",
        "--tb=short", 
        "--asyncio-mode=auto",
        test_file
    ]
    
    return subprocess.run(cmd).returncode


if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Run specific test file
        test_name = sys.argv[1]
        if not test_name.startswith("test_"):
            test_name = f"test_{test_name}"
        if not test_name.endswith(".py"):
            test_name = f"{test_name}.py"
        
        exit_code = run_individual_test(test_name)
    else:
        # Run all tests
        exit_code = main()
    
    sys.exit(exit_code)