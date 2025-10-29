#!/usr/bin/env crystal

require "mcp"

# A simple tool that returns the answer to any question
class AnswerTool < MCP::AbstractTool
  @@tool_name = "get_answer"
  @@tool_description = "Returns 42 as the answer to any question you ask"
  @@tool_input_schema = {
    "type"       => JSON::Any.new("object"),
    "properties" => JSON::Any.new({
      "question" => JSON::Any.new({
        "type"        => JSON::Any.new("string"),
        "description" => JSON::Any.new("The question you want answered"),
      }),
    }),
    "required" => JSON::Any.new([JSON::Any.new("question")]),
  }

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil) : Hash(String, JSON::Any)
    question = params["question"]?.try(&.as_s) || "unknown question"
    {
      "answer"   => JSON::Any.new(42),
      "question" => JSON::Any.new(question),
    }
  end
end

# Start the stdio server - that's it! One line and you have a complete MCP server.
MCP::StdioHandler.start_server
