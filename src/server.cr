require "kemal"
require "json"
require "./tool"
require "./interfaces"

# Lightweight MCP 2024-11-05 Server Implementation
class MCP::Server
  @config : MCPConfig
  @logger : LogProvider

  def initialize(@config : MCPConfig = DefaultMCPConfig.new, @logger : LogProvider = DefaultLogProvider.new)
    # Tools will be loaded dynamically at request time
  end

  private def tools
    tools = MCP.registered_tools
    @logger.info { "MCP: Retrieved #{tools.size} registered tools: #{tools.keys}" }
    tools
  end

  # Handle MCP JSON-RPC requests via Kemal
  def handle_request(request_env, user_id : String)
    # Parse JSON-RPC request
    request_body = request_env.request.body || raise "Missing request body"
    json_request = JSON.parse(request_body)
    request_id = json_request["id"]?

    @logger.info { "MCP Request: #{json_request}" }

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
      handle_tools_call(params, id, user_id, request_env)
    else
      send_error(-32601, "Method not found: #{method}", id)
    end
  rescue ex
    @logger.error("Error handling MCP request: #{ex.message}", ex)
    send_error(-32603, "Internal error: #{ex.message}", id)
  end

  # Handle Server-Sent Events for real-time communication
  def handle_sse(env, user_id : String)
    env.response.headers["Content-Type"] = "text/event-stream"
    env.response.headers["Cache-Control"] = "no-cache"
    env.response.headers["Connection"] = "keep-alive"
    env.response.headers["Access-Control-Allow-Origin"] = "*"
    env.response.headers["Access-Control-Allow-Headers"] = "Cache-Control"

    # Send initial connection event
    env.response.puts("event: connected")
    env.response.puts("data: {\"message\": \"Connected to #{@config.server_name} as user: #{user_id}\"}")
    env.response.puts
    env.response.flush

    # Keep connection alive with periodic heartbeats
    spawn do
      loop do
        sleep(30.seconds) # Send heartbeat every 30 seconds
        begin
          env.response.puts(": heartbeat")
          env.response.puts
          env.response.flush
        rescue ex
          break # Connection closed
        end
      end
    end
  rescue ex
    @logger.error("Error in SSE connection: #{ex.message}", ex)
  end

  private def handle_initialize(params, id)
    client_version = params["protocolVersion"]?.try(&.as_s)

    # Accept 2025-06-18 (Claude) and 2024-11-05 (standard)
    unless client_version == "2025-06-18" || client_version == "2024-11-05"
      return send_error(-32602, "Unsupported protocol version: #{client_version}", id)
    end

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
          "name"    => @config.server_name,
          "version" => @config.server_version,
        },
      },
    }

    response.to_json
  end

  private def handle_tools_list(params, id)
    tools_list = tools.values.map do |tool|
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

  private def handle_tools_call(params, id, user_id : String, env)
    tool_name = params["name"]?.try(&.as_s)

    unless tool_name
      return send_error(-32602, "Missing tool name", id)
    end

    tool = tools[tool_name]?
    unless tool
      return send_error(-32602, "Unknown tool: #{tool_name}", id)
    end

    # MCP 2024-11-05 uses "arguments", 0.1.0 uses "params"
    arguments = params["arguments"]?.try(&.as_h) || params["params"]?.try(&.as_h) || {} of String => JSON::Any

    begin
      # Call tool with environment context for authentication
      result = tool.invoke(arguments, env)

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

  private def send_error(code, message, id)
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
