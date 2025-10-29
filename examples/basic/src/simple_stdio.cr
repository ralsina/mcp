#!/usr/bin/env crystal

require "mcp"

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
MCP::StdioHandler.start_server
