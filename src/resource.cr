module MCP
  # Global registry for all resources
  @@registered_resources = {} of String => AbstractResource.class

  # Collected at `inherited` time, registered lazily (see tool.cr).
  @@resource_subclasses = [] of AbstractResource.class

  def self.resource_subclasses
    @@resource_subclasses
  end

  # Returns all registered resources
  def self.registered_resources
    @@resource_subclasses.each do |resource_class|
      @@registered_resources[resource_class.resource_uri] = resource_class
    end
    @@resource_subclasses.clear
    @@registered_resources
  end

  # Registers a resource class explicitly, overriding the lazy one
  def self.register_resource(resource_class : AbstractResource.class)
    @@registered_resources[resource_class.resource_uri] = resource_class
  end

  # Abstract base class for all resources
  abstract class AbstractResource
    # Class properties that must be defined by subclasses
    class_property resource_uri : String = ""
    class_property resource_name : String = ""
    class_property resource_description : String = ""
    class_property resource_mime_type : String = "text/plain"

    # Collect the subclass; registered (with the resource_uri its body
    # assigned) the first time the registry is read.
    macro inherited
      MCP.resource_subclasses << {{@type}}
    end

    # Abstract method that must be implemented by subclasses
    # Should return the resource content as a string
    abstract def read(env : HTTP::Server::Context? = nil) : String

    # Abstract method for subscription support (optional implementation)
    # Should return true if the resource supports change notifications
    def supports_subscription? : Bool
      false
    end

    # Optional method for subscription handling
    # Default implementation does nothing
    def subscribe(env : HTTP::Server::Context? = nil) : Hash(String, JSON::Any)
      {
        "message" => JSON::Any.new("Subscription not supported for this resource"),
      }
    end

    # Default implementation for getting resource metadata
    def self.resource_metadata : Hash(String, JSON::Any)
      {
        "uri"         => JSON::Any.new(resource_uri),
        "name"        => JSON::Any.new(resource_name),
        "description" => JSON::Any.new(resource_description),
        "mimeType"    => JSON::Any.new(resource_mime_type),
      }
    end

    # Helper method to get current timestamp for change detection
    protected def current_timestamp : String
      Time.utc.to_rfc3339
    end

    # Helper method to create a basic response with metadata
    protected def create_response(content : String, metadata : Hash(String, String)? = nil) : Hash(String, JSON::Any)
      response = {
        "contents" => JSON::Any.new([{
          "uri"      => JSON::Any.new(self.class.resource_uri),
          "mimeType" => JSON::Any.new(self.class.resource_mime_type),
          "text"     => JSON::Any.new(content),
        } of String => JSON::Any]),
      }

      if metadata
        metadata.each do |key, value|
          response[key] = JSON::Any.new(value)
        end
      end

      response
    end
  end
end
