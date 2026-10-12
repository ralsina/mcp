require "spec"
require "../src/mcp"

# Regression: the `inherited` hook fires before a subclass's body runs,
# so reading tool_name/prompt_name/resource_uri there only ever saw the
# base defaults — every subclass registered under "tool" / "" instead
# of its real identity. Registries must resolve lazily, after the
# subclass bodies have executed.

class BodyNamedTool < MCP::AbstractTool
  self.tool_name = "body-named-tool"
  self.tool_description = "set in the body"

  def invoke(params : Hash(String, JSON::Any), env = nil)
    {} of String => JSON::Any
  end
end

class BodyNamedPrompt < MCP::AbstractPrompt
  self.prompt_name = "body-named-prompt"

  def invoke(arguments : Hash(String, JSON::Any), env = nil) : Hash(String, JSON::Any)
    {"messages" => JSON.parse("[]")}
  end
end

class BodyNamedResource < MCP::AbstractResource
  self.resource_uri = "file://body-named"

  def read(env = nil) : String
    "content"
  end
end

class OverrideTool < MCP::AbstractTool
  self.tool_name = "override-me"

  def invoke(params : Hash(String, JSON::Any), env = nil)
    {} of String => JSON::Any
  end
end

describe "lazy registration" do
  it "registers tools under the name set in the subclass body" do
    MCP.registered_tools["body-named-tool"].should be_a(BodyNamedTool)
    MCP.registered_tools["tool"]?.should be_nil
    MCP.registered_tools["body-named-tool"].name.should eq("body-named-tool")
  end

  it "registers prompts under the prompt_name set in the subclass body" do
    MCP.registered_prompts["body-named-prompt"].should eq(BodyNamedPrompt)
  end

  it "registers resources under the resource_uri set in the subclass body" do
    MCP.registered_resources["file://body-named"].should eq(BodyNamedResource)
  end

  it "lets explicit registrations override lazy ones" do
    MCP.register_tool("override-me", OverrideTool.new)
    MCP.registered_tools["override-me"].should be_a(OverrideTool)
  end
end
