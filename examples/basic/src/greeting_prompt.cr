# Example prompt that generates personalized greetings
class GreetingPrompt < MCP::AbstractPrompt
  @@prompt_name = "greeting"
  @@prompt_description = "Generate a personalized greeting message"
  @@prompt_arguments = {
    "type" => "object",
    "properties" => {
      "name" => {
        "type" => "string",
        "description" => "The name of the person to greet"
      },
      "time_of_day" => {
        "type" => "string",
        "description" => "Time of day for context (morning, afternoon, evening)",
        "enum" => ["morning", "afternoon", "evening"]
      },
      "formal" => {
        "type" => "boolean",
        "description" => "Whether to use formal language",
        "default" => false
      }
    },
    "required" => ["name"]
  }.to_json

  def invoke(arguments : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil) : Hash(String, JSON::Any)
    name = get_argument(arguments, "name")
    time_of_day = get_argument(arguments, "time_of_day", "day")
    formal = get_argument_bool(arguments, "formal", false)

    greeting = case time_of_day
               when "morning"
                 formal ? "Good morning" : "Good morning"
               when "afternoon"
                 formal ? "Good afternoon" : "Good afternoon"
               when "evening"
                 formal ? "Good evening" : "Good evening"
               else
                 formal ? "Hello" : "Hi"
               end

    message = if formal
                "#{greeting}, #{name}. I hope you are having a pleasant day."
              else
                "#{greeting}, #{name}! How's it going?"
              end

    {
      "messages" => JSON::Any.new([JSON::Any.new({
        "role"    => JSON::Any.new("user"),
        "content" => JSON::Any.new({
          "type" => JSON::Any.new("text"),
          "text" => JSON::Any.new(message),
        } of String => JSON::Any),
      })])
    }
  end
end