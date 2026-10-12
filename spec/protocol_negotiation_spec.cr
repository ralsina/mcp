require "spec"
require "../src/mcp"
require "kemal"

# Regression: rejecting an initialize because the client's
# protocolVersion is NEWER than ours breaks the whole handshake.
# Per the spec, an older server answers with its own latest version
# and lets the client decide.
describe "protocol version negotiation" do
  it "accepts a newer client protocolVersion, answering with ours" do
    handler = MCP::Handler.new(NoopAuth.new, MCP::DefaultLogProvider.new, MCP::Server.new)
    request = HTTP::Request.new("POST", "/mcp", HTTP::Headers{"Content-Type" => "application/json"}, IO::Memory.new(%({"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"zcode","version":"1.0"}}})))
    response_io = IO::Memory.new
    response = HTTP::Server::Response.new(response_io)
    context = HTTP::Server::Context.new(request, response)
    handler.handle_post(context)
    response.close
    raw = response_io.to_s
    # Kemal may write the full head when driven outside its pipeline.
    body = raw.starts_with?("HTTP/") ? raw.partition("\r\n\r\n")[2] : raw
    result = JSON.parse(body)
    result["result"]["protocolVersion"].as_s.should eq("2024-11-05")
    result["result"]["serverInfo"]["name"].as_s.should eq("MCP Server")
  end
end

class NoopAuth < MCP::AuthProvider
  def get_user_id(env) : String
    "test"
  end

  def authenticate?(env) : Bool
    true
  end
end
