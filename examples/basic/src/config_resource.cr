# Example resource that provides configuration information
class ConfigResource < MCP::AbstractResource
  @@resource_uri = "config://server"
  @@resource_name = "Server Configuration"
  @@resource_description = "Current server configuration and settings"
  @@resource_mime_type = "application/json"

  def initialize(@config_data : Hash(String, String) = {} of String => String)
    # Set some default config values
    @config_data = {
      "server_name" => "MCP Server",
      "version" => "0.1.0",
      "log_level" => "info",
      "max_connections" => "100",
      "timeout" => "30"
    } of String => String
  end

  def read(env : HTTP::Server::Context? = nil) : String
    config_response = @config_data.dup
    config_response["last_updated"] = current_timestamp
    config_response.to_json
  end

  def supports_subscription? : Bool
    false
  end

  def subscribe(env : HTTP::Server::Context? = nil) : Hash(String, JSON::Any)
    {
      "message" => JSON::Any.new("This resource does not support subscriptions")
    }
  end
end