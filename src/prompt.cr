module MCP
  # Global registry for all prompts
  @@registered_prompts = {} of String => AbstractPrompt.class

  # Collected at `inherited` time, registered lazily (see tool.cr).
  @@prompt_subclasses = [] of AbstractPrompt.class

  def self.prompt_subclasses
    @@prompt_subclasses
  end

  # Returns all registered prompts
  def self.registered_prompts
    @@prompt_subclasses.each do |prompt_class|
      @@registered_prompts[prompt_class.prompt_name] = prompt_class
    end
    @@prompt_subclasses.clear
    @@registered_prompts
  end

  # Registers a prompt class explicitly, overriding the lazy one
  def self.register_prompt(prompt_class : AbstractPrompt.class)
    @@registered_prompts[prompt_class.prompt_name] = prompt_class
  end

  # Abstract base class for all prompts
  abstract class AbstractPrompt
    # Class properties that must be defined by subclasses
    class_property prompt_name : String = ""
    class_property prompt_description : String = ""
    class_property prompt_arguments : String = "{}"

    # Collect the subclass; registered (with the prompt_name its body
    # assigned) the first time the registry is read.
    macro inherited
      MCP.prompt_subclasses << {{@type}}
    end

    # Abstract method that must be implemented by subclasses
    # Should return a hash containing the prompt content and messages
    abstract def invoke(arguments : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil) : Hash(String, JSON::Any)

    # Default implementation for getting prompt metadata
    def self.prompt_metadata : Hash(String, JSON::Any)
      {
        "name"        => JSON::Any.new(prompt_name),
        "description" => JSON::Any.new(prompt_description),
        "arguments"   => JSON.parse(prompt_arguments),
      }
    end

    # Helper method to validate required arguments
    protected def validate_arguments(arguments : Hash(String, JSON::Any), required_args : Array(String))
      missing_args = required_args.select { |arg| !arguments.has_key?(arg) }
      unless missing_args.empty?
        raise ArgumentError.new("Missing required arguments: #{missing_args.join(", ")}")
      end
    end

    # Helper method to get argument value with type conversion
    protected def get_argument(arguments : Hash(String, JSON::Any), key : String, default = nil)
      arguments[key]?.try(&.as_s) || default
    end

    # Helper method to get argument as integer
    protected def get_argument_i(arguments : Hash(String, JSON::Any), key : String, default = 0)
      arguments[key]?.try(&.as_i) || default
    end

    # Helper method to get argument as boolean
    protected def get_argument_bool(arguments : Hash(String, JSON::Any), key : String, default = false)
      arguments[key]?.try(&.as_bool) || default
    end
  end
end
