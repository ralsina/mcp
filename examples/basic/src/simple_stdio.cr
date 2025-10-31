#!/usr/bin/env crystal

require "mcp"

# Import our example prompts and resources
require "./greeting_prompt"
require "./code_review_prompt"
require "./log_file_resource"
require "./memory_resource"
require "./config_resource"

# A simple tool that returns the answer to any question
class AnswerTool < MCP::AbstractTool
  @@tool_name = "get_answer"
  @@tool_description = "Returns 42 as the answer to any question you ask"
  @@tool_input_schema = {
    "type"       => "object",
    "properties" => {
      "question" => {
        "type"        => "string",
        "description" => "The question you want answered",
      },
    },
    "required" => ["question"],
  }.to_json

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    question = params["question"]?.try(&.as_s) || "unknown question"
    {
      "answer"   => 42,
      "question" => question,
    }
  end
end

# Start the stdio server - that's it! One line and you have a complete MCP server.
puts "MCP Server starting with:"
puts "- Tools: #{MCP.registered_tools.keys.join(", ")}"
puts "- Prompts: #{MCP.registered_prompts.keys.join(", ")}"
puts "- Resources: #{MCP.registered_resources.keys.join(", ")}"
puts "---"

MCP::StdioHandler.start_server
