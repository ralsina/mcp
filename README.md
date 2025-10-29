# MCP Crystal Shard

A lightweight, reusable Crystal implementation of the Model Context Protocol (MCP) for building JSON-RPC servers that expose tools to AI assistants.

## Features

- **Tool Registry**: Automatic registration of tools via macro-based inheritance
- **JSON-RPC 2.0**: Full compliance with MCP protocol specifications
- **Server-Sent Events**: Real-time communication support
- **Dependency Injection**: Clean separation via interfaces for auth, logging, and config
- **Kemal Integration**: Easy integration with Kemal web framework

## Quick Start

Add to your `shard.yml`:

```yaml
dependencies:
  mcp:
    github: ralsina/mcp
```

### Simple stdio MCP Server

```crystal
require "mcp"

# Define your tool by inheriting from AbstractTool
class MyTool < MCP::AbstractTool
  @@tool_name = "my_tool"
  @@tool_description = "A simple example tool that returns 42"
  @@tool_input_schema = {
    "type"       => JSON::Any.new("object"),
    "properties" => JSON::Any.new({} of String => JSON::Any),
  }

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil) : Hash(String, JSON::Any)
    {
      "result" => JSON::Any.new(42)
    }
  end
end

# Start a simple stdio MCP server
MCP::StdioHandler.start_server
```

That's it! Your MCP server is ready to handle requests via stdin/stdout.

### Web Server Integration

```crystal
require "kemal"
require "mcp"

# Create your tools
class EchoTool < MCP::AbstractTool
  @@tool_name = "echo"
  @@tool_description = "Echoes back the input message"
  @@tool_input_schema = {
    "type"       => JSON::Any.new("object"),
    "properties" => JSON::Any.new({
      "message" => JSON::Any.new({
        "type"        => JSON::Any.new("string"),
        "description" => JSON::Any.new("Message to echo back"),
      }),
    }),
    "required" => JSON::Any.new(["message"]),
  }

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil) : Hash(String, JSON::Any)
    message = params["message"]?.try(&.as_s) || "no message"
    {
      "echo" => JSON::Any.new(message)
    }
  end
end

# Set up MCP server
mcp_server = MCP::Server.new

# Kemal routes
post "/mcp" do |env|
  # Simple user ID extraction (implement your own auth)
  user_id = env.request.headers["User-Id"]? || "anonymous"

  response = mcp_server.handle_request(env, user_id)
  env.response.content_type = "application/json"
  response
end

get "/mcp" do |env|
  user_id = env.request.headers["User-Id"]? || "anonymous"
  mcp_server.handle_sse(env, user_id)
end

Kemal.run
```

## Architecture

The shard provides these core components:

- **`MCP::AbstractTool`**: Base class for all tools with automatic registration
- **`MCP::Server`**: Handles JSON-RPC requests and SSE connections
- **`MCP::Handler`**: Kemal integration layer
- **Interface classes**: For auth, logging, and configuration injection

## Tool Registration

Tools are automatically registered when the class is defined:

```crystal
class MyTool < MCP::AbstractTool
  # Tool metadata
  @@tool_name = "my_tool"
  @@tool_description = "Does something useful"
  @@tool_input_schema = {
    "type" => JSON::Any.new("object"),
    "properties" => JSON::Any.new({
      "input" => JSON::Any.new({
        "type" => JSON::Any.new("string"),
        "description" => JSON::Any.new("Input parameter"),
      }),
    }),
    "required" => JSON::Any.new(["input"]),
  }

  # Implementation
  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    # Your tool logic here
    {
      "result" => JSON::Any.new("processed: #{params["input"]}")
    }
  end
end
```

## Protocol Support

- **JSON-RPC 2.0**: Core protocol for request/response
- **MCP 2024-11-05**: Standard protocol version
- **Tools/List**: List available tools with metadata
- **Tools/Call**: Execute tools with parameters
- **Server-Sent Events**: Real-time updates and streaming

## Examples

See the `examples/` directory for complete working examples:

### Basic Example (`examples/basic/`)
- Simple stdio MCP server
- Demonstrates core tool registration and JSON-RPC handling
- Perfect for command-line MCP servers

### Web Example (`examples/web/`)
- Web-based MCP server using Kemal framework
- HTTP JSON-RPC endpoint and Server-Sent Events
- Demonstrates authentication, logging, and HTTP context access
- Includes built-in web interface for testing

## License

MIT License - see LICENSE file for details.