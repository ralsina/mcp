require "json"

# Global tool registry that's shared across all tool classes
module MCP
  @@registered_tools = {} of String => AbstractTool

  def self.registered_tools
    @@registered_tools
  end

  def self.register_tool(name : String, tool : AbstractTool)
    @@registered_tools[name] = tool
  end
end

# Base class for MCP tools
abstract class MCP::AbstractTool
  getter name : String
  getter description : String
  getter input_schema : String

  # Class properties that can be overridden by subclasses
  class_property tool_name : String = "tool"
  class_property tool_description : String = "A generic tool"
  class_property tool_input_schema : String = "{\"type\": \"object\", \"properties\": {}}"

  def initialize
    @name = @@tool_name
    @description = @@tool_description
    @input_schema = @@tool_input_schema
  end

  # Register this tool when the file is loaded
  macro inherited
    # Register the tool in the framework's registry
    {% begin %}
      tool_name = {{@type}}.tool_name
      MCP.register_tool(tool_name, {{@type}}.new)
    {% end %}
  end

  abstract def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
end
