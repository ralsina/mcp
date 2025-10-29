# Basic MCP Example

A minimal stdio-based MCP server demonstrating the core functionality of the MCP Crystal shard.

## What It Does

This example implements a simple tool:
- `get_answer` - Returns 42 as the answer to any question you ask

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
   ./bin/basic_mcp
   ```

Or run directly without building:
```bash
crystal run src/simple_stdio.cr
```

## Testing

Test it by sending JSON-RPC requests via stdin:

**List available tools:**
```bash
echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' | ./bin/basic_mcp
```

**Call the get_answer tool:**
```bash
echo '{"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "get_answer", "arguments": {"question": "What is the meaning of life?"}}}' | ./bin/basic_mcp
```

**Initialize the connection:**
```bash
echo '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05"}}' | ./bin/basic_mcp
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
        "name": "get_answer",
        "description": "Returns 42 as the answer to any question you ask",
        "inputSchema": {
          "type": "object",
          "properties": {
            "question": {
              "type": "string",
              "description": "The question you want answered"
            }
          },
          "required": ["question"]
        }
      }
    ]
  }
}
```

**get_answer response:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "answer": 42,
    "question": "What is the meaning of life?"
  }
}
```

## Key Concepts Demonstrated

1. **Tool Registration**: Tools are automatically registered when the class is defined
2. **JSON-RPC 2.0**: Full protocol compliance for requests and responses
3. **Stdio Communication**: Simple stdin/stdout communication pattern
4. **Error Handling**: Graceful error responses for invalid requests

This example shows just how easy it is to create a functional MCP server using the shard!