# Example resource that provides access to a log file
class LogFileResource < MCP::AbstractResource
  @@resource_uri = "log://server.log"
  @@resource_name = "Server Log File"
  @@resource_description = "Access to the server's log file contents"
  @@resource_mime_type = "text/plain"

  def initialize(@log_path : String = "server.log")
  end

  def read(env : HTTP::Server::Context? = nil) : String
    if File.exists?(@log_path)
      begin
        File.read(@log_path)
      rescue ex
        "Error reading log file: #{ex.message}"
      end
    else
      "Log file not found at #{@log_path}"
    end
  end

  def supports_subscription? : Bool
    true
  end

  def subscribe(env : HTTP::Server::Context? = nil) : Hash(String, JSON::Any)
    # In a real implementation, this would set up a subscription to log changes
    # For now, we'll just return a subscription confirmation
    {
      "message" => JSON::Any.new("Subscribed to log file changes"),
      "uri" => JSON::Any.new(@@resource_uri),
      "lastModified" => JSON::Any.new(current_timestamp)
    }
  end
end