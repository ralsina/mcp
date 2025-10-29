# Built-in stdio handler for MCP servers
# Provides a simple way to create stdio-based MCP servers without web framework dependencies

class MCP::StdioHandler
  def self.handle_request(json_body : String, user_id : String = "stdio_user")
    # Parse JSON-RPC request
    json_request = JSON.parse(json_body)
    request_id = json_request["id"]?

    # Validate JSON-RPC 2.0 format
    unless json_request["jsonrpc"]? == "2.0"
      return send_error(-32600, "Invalid Request", request_id)
    end

    method = json_request["method"]?.try(&.as_s)
    id = json_request["id"]?
    params = json_request["params"]?.try(&.as_h) || {} of String => JSON::Any

    case method
    when "initialize"
      handle_initialize(params, id)
    when "tools/list"
      handle_tools_list(params, id)
    when "tools/call"
      handle_tools_call(params, id, user_id)
    else
      send_error(-32601, "Method not found: #{method}", id)
    end
  rescue ex
    send_error(-32603, "Internal error: #{ex.message}", nil)
  end

  # Start a simple stdio MCP server that runs until stdin is closed
  def self.start_server(user_id : String = "stdio_user")
    puts "MCP stdio server started. Available tools:"
    puts MCP.registered_tools.keys.join(", ")
    puts "---"
    STDOUT.flush

    while !STDIN.closed?
      begin
        line = STDIN.gets
        break unless line

        line = line.strip
        next if line.empty?

        # Handle the request
        response = handle_request(line, user_id)

        # Send response
        puts response
        STDOUT.flush
      rescue ex
        error_response = {
          "jsonrpc" => "2.0",
          "error"   => {
            "code"    => -32603,
            "message" => "Internal error: #{ex.message}",
          },
          "id" => nil,
        }
        puts error_response.to_json
        STDOUT.flush
      end
    end
  end

  private def self.handle_initialize(params, id)
    response = {
      "jsonrpc" => "2.0",
      "id"      => id,
      "result"  => {
        "protocolVersion" => "2024-11-05",
        "capabilities"    => {
          "tools" => {
            "listChanged" => true,
          },
        },
        "serverInfo" => {
          "name"    => "MCP Server",
          "version" => "0.1.0",
        },
      },
    }

    response.to_json
  end

  private def self.handle_tools_list(params, id)
    tools_list = MCP.registered_tools.values.map do |tool|
      {
        "name"        => tool.name,
        "description" => tool.description,
        "inputSchema" => tool.input_schema,
      }
    end

    response = {
      "jsonrpc" => "2.0",
      "id"      => id,
      "result"  => {
        "tools" => tools_list,
      },
    }

    response.to_json
  end

  private def self.handle_tools_call(params, id, user_id : String)
    tool_name = params["name"]?.try(&.as_s)

    unless tool_name
      return send_error(-32602, "Missing tool name", id)
    end

    tool = MCP.registered_tools[tool_name]?
    unless tool
      return send_error(-32602, "Unknown tool: #{tool_name}", id)
    end

    # MCP 2024-11-05 uses "arguments", 0.1.0 uses "params"
    arguments = params["arguments"]?.try(&.as_h) || params["params"]?.try(&.as_h) || {} of String => JSON::Any

    begin
      # Call tool with no environment (stdio doesn't have HTTP context)
      result = tool.invoke(arguments, nil)

      response = {
        "jsonrpc" => "2.0",
        "id"      => id,
        "result"  => result,
      }

      response.to_json
    rescue ex : Exception
      send_error(-32602, "Tool error: #{ex.message}", id)
    end
  end

  private def self.send_error(code, message, id)
    error_response = Hash(String, JSON::Any).new
    error_response["jsonrpc"] = JSON::Any.new("2.0")
    error_response["error"] = JSON::Any.new({
      "code"    => JSON::Any.new(code),
      "message" => JSON::Any.new(message),
    } of String => JSON::Any)

    # Only include id if it exists and is not nil
    if id && !id.nil?
      error_response["id"] = id
    end

    error_response.to_json
  end
end
