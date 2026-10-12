require "json"

# Global tool registry that's shared across all tool classes
module MCP
  @@registered_tools = {} of String => AbstractTool

  # Subclasses are collected when defined and instantiated lazily: the
  # `inherited` hook fires BEFORE the subclass's body runs, so reading
  # its tool_name there would only ever see the base defaults.
  @@tool_subclasses = [] of AbstractTool.class

  def self.tool_subclasses
    @@tool_subclasses
  end

  def self.registered_tools
    @@tool_subclasses.each do |subclass|
      tool = subclass.new
      @@registered_tools[tool.name] = tool
    end
    @@tool_subclasses.clear
    @@registered_tools
  end

  # Explicit registration, overriding the lazy one.
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

  # Collect the subclass; it is registered (with the name its body
  # assigned) the first time the registry is read.
  macro inherited
    MCP.tool_subclasses << {{@type}}
  end

  abstract def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
end
