# Abstraction interfaces for MCP framework
# These allow the MCP shard to be independent of specific application implementations

# Interface for authentication providers
abstract class MCP::AuthProvider
  abstract def get_user_id(env) : String
  abstract def authenticate?(env) : Bool
end

# Interface for logging providers
abstract class MCP::LogProvider
  abstract def info(&)
  abstract def error(message : String, exception : Exception? = nil)
  abstract def debug(message : String)
  abstract def warn(message : String)
end

# Interface for MCP configuration
abstract class MCP::MCPConfig
  abstract def enabled? : Bool
  abstract def protocol_version : String
  abstract def server_name : String
  abstract def server_version : String
end

# Default implementation that can be overridden by the host application
class MCP::DefaultLogProvider < MCP::LogProvider
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

# Default configuration that can be used as base class
class MCP::DefaultMCPConfig < MCP::MCPConfig
  def enabled? : Bool
    true
  end

  def protocol_version : String
    "2024-11-05"
  end

  def server_name : String
    "MCP Server"
  end

  def server_version : String
    "0.1.0"
  end
end
