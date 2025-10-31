# Example resource that provides system memory information
class MemoryResource < MCP::AbstractResource
  @@resource_uri = "system://memory"
  @@resource_name = "System Memory Information"
  @@resource_description = "Current system memory usage and statistics"
  @@resource_mime_type = "application/json"

  def read(env : HTTP::Server::Context? = nil) : String
    begin
      # Try to read memory info from /proc/meminfo on Linux
      if File.exists?("/proc/meminfo")
        meminfo = File.read("/proc/meminfo")
        memory_data = parse_meminfo(meminfo)
        memory_data.to_json
      else
        # Fallback for other systems - provide basic info
        {
          "total_memory" => "Unknown",
          "available_memory" => "Unknown",
          "platform" => "Non-Linux system"
        }.to_json
      end
    rescue ex
      {
        "error" => "Failed to read memory information: #{ex.message}",
        "platform" => "Error"
      }.to_json
    end
  end

  def supports_subscription? : Bool
    true
  end

  def subscribe(env : HTTP::Server::Context? = nil) : Hash(String, JSON::Any)
    {
      "message" => JSON::Any.new("Subscribed to memory usage updates"),
      "uri" => JSON::Any.new(@@resource_uri),
      "updateFrequency" => JSON::Any.new("30s"),
      "lastUpdated" => JSON::Any.new(current_timestamp)
    }
  end

  private def parse_meminfo(meminfo : String) : Hash(String, String)
    data = {} of String => String
    meminfo.each_line do |line|
      if match = line.match(/^(\w+):\s+(\d+)\s*kB/)
        key = match[1].downcase
        value = match[2]
        data[key] = value
      end
    end

    # Calculate available memory if we have the required fields
    if data.has_key?("memtotal") && data.has_key?("memavailable")
      total = data["memtotal"].to_i
      available = data["memavailable"].to_i
      used = total - available
      data["used"] = used.to_s
      data["usage_percent"] = ((used.to_f / total) * 100).round(2).to_s
    end

    data
  end
end