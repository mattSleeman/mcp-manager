# MCP Manager

A macOS menu bar application for managing Model Context Protocol (MCP) servers for Claude Desktop.

<img width="360" alt="MCP Manager Screenshot" src="https://github.com/user-attachments/assets/placeholder">

## Features

- 🎯 **Menu Bar Access** - Quick access from your macOS menu bar
- ✏️ **Edit Servers** - Add, edit, and remove MCP servers through a GUI
- 🔍 **Search** - Filter servers by name
- 🌍 **Environment Variables** - Manage env vars for each server
- 🔄 **Auto-Sync** - Automatically detects changes to Claude config files
- ✅ **Enable/Disable** - Toggle servers on/off without deleting them
- 🎨 **Server Types** - Supports Local (stdio), HTTP, and SSE servers

## Installation

### Option 1: Download Release (Recommended)

1. Download the latest `MCPManager.app.zip` from [Releases](https://github.com/mattSleeman/mcp-manager/releases)
2. Unzip and move `MCPManager.app` to your Applications folder
3. Right-click the app and select "Open" (required for first launch on macOS)
4. The app will appear in your menu bar

### Option 2: Build from Source

**Requirements:**
- macOS 12.0 or later
- Xcode 14.0 or later

**Steps:**

1. Clone the repository:
```bash
git clone https://github.com/mattSleeman/mcp-manager.git
cd mcp-manager
```

2. Open the project in Xcode:
```bash
open MCPManager.xcodeproj
```

3. Build and run:
   - Select your Mac as the target device
   - Press `Cmd + R` to build and run
   - Or use Product → Archive to create a distributable app

## Usage

### Adding a Server

1. Click the MCP Manager icon in your menu bar
2. Click "Add Server"
3. Fill in the details:
   - **Name**: Unique identifier for your server
   - **Type**: Choose Local (stdio), HTTP, or SSE
   - **Command/URL**: Depending on type
   - **Arguments**: For local servers (supports quoted strings)
   - **Environment Variables**: Optional key-value pairs

4. Click "Add Server"

### Editing a Server

1. Click on a server to expand its details
2. Click "Edit"
3. Modify the configuration in the popup window
4. Click "Save Changes"

### Deleting a Server

1. Click on a server to expand its details
2. Click "Remove"
3. Confirm deletion in the dialog

### Enable/Disable Servers

Toggle the switch next to any server to enable or disable it without deleting the configuration.

## Configuration Files

MCP Manager reads and writes to Claude Desktop's configuration files:

- `~/.claude.json` - Main MCP server configuration
- `~/.claude/settings.json` - Claude settings (read-only in app)

The app automatically watches these files for external changes and updates the UI accordingly.

## Examples

### Local Server (stdio)

```
Name: filesystem
Type: Local (stdio)
Command: npx
Arguments: -y @modelcontextprotocol/server-filesystem /tmp
```

### HTTP Server

```
Name: my-api
Type: HTTP
URL: http://localhost:3000
```

### With Environment Variables

```
Name: database-server
Type: Local (stdio)
Command: node
Arguments: server.js
Environment:
  DB_HOST=localhost
  DB_PORT=5432
```

## Argument Parsing

The app supports shell-style argument parsing:
- Space-separated: `arg1 arg2 arg3`
- Quoted strings: `"path with spaces" arg2`
- Escaped characters: `path\ with\ spaces`

## Troubleshooting

### App won't open
- Right-click and select "Open" for first launch
- Check System Settings → Privacy & Security

### Changes not saving
- Ensure `~/.claude.json` is writable
- Check for JSON syntax errors in the file

### Servers not appearing
- Verify `~/.claude.json` exists and is valid JSON
- Click the refresh button in the app header

## Development

Built with:
- SwiftUI
- AppKit
- macOS 12.0+

## License

MIT License - see LICENSE file for details

## Contributing

Contributions welcome! Please open an issue or submit a pull request.

## Support

For issues or questions, please [open an issue](https://github.com/mattSleeman/mcp-manager/issues) on GitHub.
