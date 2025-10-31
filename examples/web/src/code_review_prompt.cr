# Example prompt that helps with code review
class CodeReviewPrompt < MCP::AbstractPrompt
  @@prompt_name = "code_review"
  @@prompt_description = "Generate a code review prompt for analyzing code quality"
  @@prompt_arguments = {
    "type" => "object",
    "properties" => {
      "language" => {
        "type" => "string",
        "description" => "Programming language being reviewed",
        "enum" => ["crystal", "javascript", "python", "java", "ruby", "go", "rust"]
      },
      "focus_areas" => {
        "type" => "array",
        "description" => "Specific areas to focus on during review",
        "items" => {
          "type" => "string",
          "enum" => ["security", "performance", "readability", "maintainability", "testing", "documentation"]
        },
        "default" => ["readability", "maintainability"]
      },
      "severity_level" => {
        "type" => "string",
        "description" => "Minimum severity level to report",
        "enum" => ["critical", "major", "minor", "info"],
        "default" => "minor"
      }
    },
    "required" => ["language"]
  }.to_json

  def invoke(arguments : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil) : Hash(String, JSON::Any)
    language = get_argument(arguments, "language")
    focus_areas_json = arguments["focus_areas"]? || JSON::Any.new([JSON::Any.new("readability"), JSON::Any.new("maintainability")])
    focus_areas = focus_areas_json.as_a.map(&.as_s)
    severity_level = get_argument(arguments, "severity_level", "minor")

    focus_text = focus_areas.join(", ")

    prompt_text = "Please review the following #{language} code with a focus on: #{focus_text}. "
    prompt_text += "Report issues with a severity level of #{severity_level} or higher. "
    prompt_text += "Provide specific, actionable feedback and suggest improvements where appropriate."

    {
      "messages" => JSON::Any.new([JSON::Any.new({
        "role"    => JSON::Any.new("user"),
        "content" => JSON::Any.new({
          "type" => JSON::Any.new("text"),
          "text" => JSON::Any.new(prompt_text),
        } of String => JSON::Any),
      })])
    }
  end
end