require "kemal"
require "mcp"

# Import our example prompts and resources
require "./greeting_prompt"
require "./code_review_prompt"
require "./log_file_resource"
require "./memory_resource"
require "./config_resource"

# Define some example tools for the web-based MCP server

class EchoTool < MCP::AbstractTool
  @@tool_name = "echo"
  @@tool_description = "Echoes back the input message"
  @@tool_input_schema = {
    "type"       => "object",
    "properties" => {
      "message" => {
        "type"        => "string",
        "description" => "Message to echo back",
      },
    },
    "required" => ["message"],
  }.to_json

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    message = params["message"]?.try(&.as_s) || "no message"
    {
      "echo" => message,
    }
  end
end

class MathTool < MCP::AbstractTool
  @@tool_name = "math_add"
  @@tool_description = "Adds two numbers together"
  @@tool_input_schema = {
    "type"       => "object",
    "properties" => {
      "a" => {
        "type"        => "number",
        "description" => "First number",
      },
      "b" => {
        "type"        => "number",
        "description" => "Second number",
      },
    },
    "required" => ["a", "b"],
  }.to_json

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    a = params["a"]?.try(&.as_f) || 0.0
    b = params["b"]?.try(&.as_f) || 0.0
    result = a + b

    {
      "result"    => result,
      "operation" => "#{a} + #{b} = #{result}",
    }
  end
end

class RequestInfoTool < MCP::AbstractTool
  @@tool_name = "request_info"
  @@tool_description = "Returns information about the current HTTP request"
  @@tool_input_schema = {
    "type"       => "object",
    "properties" => {} of String => String,
  }.to_json

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    if env
      {
        "method"         => env.request.method,
        "path"           => env.request.path,
        "user_agent"     => env.request.headers["User-Agent"]? || "unknown",
        "remote_address" => env.request.remote_address.to_s,
      }
    else
      {
        "error" => "No HTTP context available",
      }
    end
  end
end

# Simple auth provider that gets user ID from headers
class SimpleAuthProvider < MCP::AuthProvider
  def get_user_id(env) : String
    env.request.headers["User-Id"]? || env.request.headers["X-User-ID"]? || "anonymous"
  end

  def authenticate?(env) : Bool
    # For demo purposes, we accept all requests
    # In production, implement proper authentication
    true
  end
end

# Simple logger for the web example
class WebLogger < MCP::LogProvider
  def info(&)
    puts "[INFO] #{yield}"
  end

  def error(message : String, exception : Exception? = nil)
    if exception
      puts "[ERROR] #{message}: #{exception.message}"
    else
      puts "[ERROR] #{message}"
    end
  end

  def debug(message : String)
    puts "[DEBUG] #{message}"
  end

  def warn(message : String)
    puts "[WARN] #{message}"
  end
end

# Set up MCP server
mcp_server = MCP::Server.new
auth_provider = SimpleAuthProvider.new
logger = WebLogger.new

# Kemal routes
post "/mcp" do |env|
  logger.info { "Received MCP POST request from #{auth_provider.get_user_id(env)}" }

  # Handle the request
  response = mcp_server.handle_request(env, auth_provider.get_user_id(env))
  env.response.content_type = "application/json"
  response
end

get "/mcp" do |env|
  logger.info { "MCP SSE connection established for #{auth_provider.get_user_id(env)}" }
  mcp_server.handle_sse(env, auth_provider.get_user_id(env))
end

# Health check endpoint
get "/health" do
  {
    "status"    => "ok",
    "server"    => "MCP Web Example",
    "tools"     => MCP.registered_tools.keys,
    "prompts"   => MCP.registered_prompts.keys,
    "resources" => MCP.registered_resources.keys,
  }.to_json
end

# Simple web interface for testing
get "/" do
  <<-HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>MCP Web Example</title>
        <style>
            body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
            .endpoint { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
            .method { color: #fff; padding: 2px 8px; border-radius: 3px; font-weight: bold; }
            .post { background: #49cc90; }
            .get { background: #61affe; }
            pre { background: #f8f8f8; padding: 10px; border-radius: 3px; overflow-x: auto; }
        </style>
    </head>
    <body>
        <h1>MCP Web Example Server</h1>
        <p>This is a web-based MCP server implementation using Kemal.</p>

        <h2>Available Endpoints</h2>

        <div class="endpoint">
            <span class="method post">POST</span> <code>/mcp</code>
            <p>JSON-RPC endpoint for MCP requests</p>
            <pre>curl -X POST http://localhost:3000/mcp \\
  -H "Content-Type: application/json" \\
  -H "User-Id: test-user" \\
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'</pre>
        </div>

        <div class="endpoint">
            <span class="method get">GET</span> <code>/mcp</code>
            <p>Server-Sent Events endpoint for real-time communication</p>
        </div>

        <div class="endpoint">
            <span class="method get">GET</span> <code>/health</code>
            <p>Health check endpoint</p>
        </div>

        <h2>Available Tools</h2>
        <ul>
            <li><strong>echo</strong> - Echoes back a message</li>
            <li><strong>math_add</strong> - Adds two numbers together</li>
            <li><strong>request_info</strong> - Returns HTTP request information</li>
        </ul>

        <h2>Available Prompts</h2>
        <ul>
            <li><strong>greeting</strong> - Generate personalized greeting messages</li>
            <li><strong>code_review</strong> - Generate code review prompts</li>
        </ul>

        <h2>Available Resources</h2>
        <ul>
            <li><strong>log://server.log</strong> - Server log file access</li>
            <li><strong>system://memory</strong> - System memory information</li>
            <li><strong>config://server</strong> - Server configuration</li>
        </ul>

        <h2>Example API Calls</h2>

        <h3>Tool Call</h3>
        <pre>curl -X POST http://localhost:3001/mcp \\
  -H "Content-Type: application/json" \\
  -H "User-Id: test-user" \\
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "echo",
      "arguments": {"message": "Hello from MCP!"}
    }
  }'</pre>

        <h3>Prompt Call</h3>
        <pre>curl -X POST http://localhost:3001/mcp \\
  -H "Content-Type: application/json" \\
  -H "User-Id: test-user" \\
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "prompts/get",
    "params": {
      "name": "greeting",
      "arguments": {
        "name": "Alice",
        "time_of_day": "morning",
        "formal": true
      }
    }
  }'</pre>

        <h3>Resource Read</h3>
        <pre>curl -X POST http://localhost:3001/mcp \\
  -H "Content-Type: application/json" \\
  -H "User-Id: test-user" \\
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "resources/read",
    "params": {
      "uri": "config://server"
    }
  }'</pre>
    </body>
    </html>
  HTML
end

# Configure Kemal
Kemal.config.env = "development"
Kemal.config.port = 3001
Kemal.config.host_binding = "0.0.0.0"

puts "Starting MCP Web Server on http://localhost:3001"
puts "Available tools: #{MCP.registered_tools.keys.join(", ")}"
puts "Available prompts: #{MCP.registered_prompts.keys.join(", ")}"
puts "Available resources: #{MCP.registered_resources.keys.join(", ")}"
puts "Endpoints:"
puts "  POST /mcp - JSON-RPC endpoint"
puts "  GET  /mcp - Server-Sent Events"
puts "  GET  /health - Health check"
puts "  GET  / - Web interface"

Kemal.run
