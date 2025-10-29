require "kemal"
require "./server"
require "./interfaces"

# Generic MCP Handler that can be configured with dependencies
class MCP::Handler
  @mcp_server : MCP::Server
  @auth_provider : MCP::AuthProvider
  @logger : MCP::LogProvider

  def initialize(@auth_provider : MCP::AuthProvider, @logger : MCP::LogProvider, @mcp_server : MCP::Server? = nil)
    @mcp_server ||= MCP::Server.new
  end

  def handle_post(env)
    # Check if MCP is enabled
    unless @mcp_server.config.enabled?
      env.response.status_code = 404
      env.response.content_type = "application/json"
      env.response.print({
        "jsonrpc" => "2.0",
        "error"   => {
          "code"    => -32601,
          "message" => "MCP support is disabled",
        },
        "id" => nil,
      }.to_json)
      return
    end

    @logger.info { "Received MCP request: #{env.request.method} #{env.request.path}" }

    # Get authenticated user from auth provider
    user_id = @auth_provider.get_user_id(env)
    @logger.info { "MCP request from authenticated user: #{user_id}" }

    # Handle the request with our server
    response = @mcp_server.handle_request(env, user_id)

    env.response.content_type = "application/json"
    env.response.print response
  end

  def handle_get(env)
    # Check if MCP is enabled
    unless @mcp_server.config.enabled?
      env.response.status_code = 404
      env.response.content_type = "text/plain"
      env.response.print "MCP support is disabled"
      return
    end

    @logger.info { "MCP SSE connection established" }

    # Get authenticated user from auth provider
    user_id = @auth_provider.get_user_id(env)
    @logger.info { "MCP SSE connection from authenticated user: #{user_id}" }

    # Handle SSE with our server
    @mcp_server.handle_sse(env, user_id)
  end
end

# Note: Kemal route definitions should be handled by the host application
# Example usage:
# post "/mcp" do |env|
#   MCPHandler.new(auth_provider, logger).handle_post(env)
# end
#
# get "/mcp" do |env|
#   MCPHandler.new(auth_provider, logger).handle_get(env)
# end
