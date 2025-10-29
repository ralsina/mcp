# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

### Building the Library
```bash
# Build the library (no release mode - never use --release)
shards build

# Build all example binaries
cd examples/basic && shards build
```

### Running Examples
```bash
# Simple stdio MCP server
cd examples/basic && ./bin/basic_mcp

# Alternative stdio server
crystal examples/basic/src/easy_stdio.cr
```

### Linting and Code Quality
```bash
# Run linter and auto-fix issues
ameba --fix

# Run linter without fixing
ameba
```

### Testing
```bash
# Run tests (currently none in main library - examples have Kemal dependency tests)
# Tests are in individual dependency libraries under examples/basic/lib/*/spec/
```

## Architecture Overview

This is a Crystal shard/library for implementing MCP (Model Context Protocol) servers. The library provides both stdio and web-based MCP server capabilities.

### Core Components

**Tool Registration System:**
- `MCP::AbstractTool` (src/tool.cr:17) - Base class for all tools
- Automatic registration via Crystal macros when classes inherit from AbstractTool
- Global registry `MCP.registered_tools` maintains all available tools
- Tools define their schema using class properties: `tool_name`, `tool_description`, `tool_input_schema`

**Server Architecture:**
- `MCP::Server` (src/server.cr:7) - Main JSON-RPC 2.0 server implementation
- `MCP::StdioHandler` (src/stdio_handler.cr:4) - Simple stdin/stdout server for CLI usage
- `MCP::Handler` (src/kemal_handler.cr:6) - Kemal web framework integration layer

**Interface-Based Design:**
- `MCP::AuthProvider` - Pluggable authentication (src/interfaces.cr:5)
- `MCP::LogProvider` - Pluggable logging (src/interfaces.cr:11)
- `MCP::MCPConfig` - Configuration abstraction (src/interfaces.cr:19)

### Protocol Support

Supports MCP 2024-11-05 standard and 2025-06-18 (Claude compatibility) with these JSON-RPC methods:
- `initialize` - Protocol negotiation and capability exchange
- `tools/list` - List available tools with metadata
- `tools/call` - Execute tools with parameters

### Tool Implementation Pattern

Tools are created by inheriting from `MCP::AbstractTool` and implementing the `invoke` method:

```crystal
class MyTool < MCP::AbstractTool
  @@tool_name = "my_tool"
  @@tool_description = "Tool description"
  @@tool_input_schema = {
    "type" => "object",
    "properties" => {
      "param" => {
        "type" => "string",
        "description" => "Parameter description"
      }
    },
    "required" => ["param"]
  }.to_json

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    # Tool implementation
    param_value = params["param"]?.try(&.as_s) || ""
    {"result" => "processed: #{param_value}"}
  end
end
```

### Deployment Modes

**Stdio Mode:** Simple command-line servers using `MCP::StdioHandler.start_server`

**Web Mode:** Kemal integration with JSON-RPC POST endpoint and SSE GET endpoint for real-time communication

### File Structure

- `src/mcp.cr` - Main module exports
- `src/tool.cr` - Tool base class and registration system
- `src/server.cr` - Core JSON-RPC server implementation
- `src/stdio_handler.cr` - Stdio server implementation
- `src/kemal_handler.cr` - Kemal web framework integration
- `src/interfaces.cr` - Abstract interfaces for dependencies
- `examples/basic/` - Working example implementations

The design emphasizes modularity, automatic registration, and support for both simple stdio servers and full web-based implementations with authentication and logging.