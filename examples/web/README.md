# Web MCP Example

A web-based MCP server demonstrating how to integrate the MCP Crystal shard with Kemal web framework.

## What It Does

This example implements three tools that showcase web-specific capabilities:
- `echo` - Echoes back any message you provide
- `math_add` - Adds two numbers together (demonstrates parameter handling)
- `request_info` - Returns information about the current HTTP request (web-specific feature)

## Features Demonstrated

- **Web Framework Integration**: Kemal-based HTTP server
- **JSON-RPC over HTTP**: POST endpoint for MCP requests
- **Server-Sent Events**: Real-time communication via GET endpoint
- **Authentication**: Simple header-based user identification
- **HTTP Context**: Tools can access request information
- **Web Interface**: Simple HTML interface for testing

## Running the Example

1. Install dependencies:
   ```bash
   shards install
   ```

2. Build the example:
   ```bash
   shards build
   ```

3. Run the server:
   ```bash
   ./bin/web_mcp
   ```

The server will start on `http://localhost:3000`

## Testing

### Web Interface
Open your browser and navigate to `http://localhost:3000` to see the built-in test interface.

### Command Line Testing

**Health check:**
```bash
curl http://localhost:3000/health
```

**List available tools:**
```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "User-Id: test-user" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

**Call the echo tool:**
```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "User-Id: test-user" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "echo",
      "arguments": {"message": "Hello from MCP!"}
    }
  }'
```

**Call the math_add tool:**
```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "User-Id: test-user" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "math_add",
      "arguments": {"a": 42, "b": 58}
    }
  }'
```

**Call the request_info tool:**
```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "User-Id: test-user" \
  -H "User-Agent: curl-test" \
  -d '{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "tools/call",
    "params": {
      "name": "request_info",
      "arguments": {}
    }
  }'
```

**Initialize the connection:**
```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "User-Id: test-user" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {"protocolVersion": "2024-11-05"}
  }'
```

**Test Server-Sent Events:**
```bash
curl -N -H "User-Id: test-user" http://localhost:3000/mcp
```

## Example Responses

**tools/list response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "echo",
        "description": "Echoes back the input message",
        "inputSchema": {
          "type": "object",
          "properties": {
            "message": {
              "type": "string",
              "description": "Message to echo back"
            }
          },
          "required": ["message"]
        }
      },
      {
        "name": "math_add",
        "description": "Adds two numbers together",
        "inputSchema": {
          "type": "object",
          "properties": {
            "a": {"type": "number", "description": "First number"},
            "b": {"type": "number", "description": "Second number"}
          },
          "required": ["a", "b"]
        }
      },
      {
        "name": "request_info",
        "description": "Returns information about the current HTTP request",
        "inputSchema": {
          "type": "object",
          "properties": {},
          "required": []
        }
      }
    ]
  }
}
```

**echo tool response:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "echo": "Hello from MCP!"
  }
}
```

**math_add tool response:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "result": 100.0,
    "operation": "42.0 + 58.0 = 100.0"
  }
}
```

**request_info tool response:**
```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": {
    "method": "POST",
    "path": "/mcp",
    "user_agent": "curl-test",
    "remote_address": "127.0.0.1:xxxxx"
  }
}
```

## Architecture

This example shows:

1. **Kemal Integration**: Using `MCP::Server` with Kemal HTTP handlers
2. **Authentication**: Simple `AuthProvider` that extracts user ID from headers
3. **HTTP Context**: Tools can access `HTTP::Server::Context` to get request information
4. **Dual Endpoints**: POST for JSON-RPC, GET for Server-Sent Events
5. **Custom Tools**: Tools that leverage web-specific capabilities

This demonstrates how to build production-ready MCP servers that can be integrated into web applications and services.