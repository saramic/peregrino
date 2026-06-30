# frozen_string_literal: true

require "net/http"

class LocalityService
  NOMINATIM_BASE = "https://nominatim.openstreetmap.org"
  USER_AGENT     = "Peregrino/0.1 (github.com/saramic/peregrino)"
  OPEN_TIMEOUT   = 3
  READ_TIMEOUT   = 8

  def self.call(lat:, lng:)
    new(lat:, lng:).call
  end

  def initialize(lat:, lng:)
    @lat = lat
    @lng = lng
  end

  def call
    data = fetch_json(URI("#{NOMINATIM_BASE}/reverse?lat=#{@lat}&lon=#{@lng}&format=json"))
    return nil unless data

    addr = data["address"] || {}
    place = addr["city"]          ||
            addr["town"]          ||
            addr["village"]       ||
            addr["hamlet"]        ||
            addr["locality"]      ||
            addr["suburb"]        ||
            addr["municipality"]  ||
            addr["county"]        ||
            data["name"].presence
    return nil unless place

    { place:, address: addr }
  end

  private

  def fetch_json(uri)
    req = Net::HTTP::Get.new(uri)
    req["User-Agent"] = USER_AGENT
    req["Accept"]     = "application/json"
    res = Net::HTTP.start(uri.host, uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    ) { |h| h.request(req) }
    return nil unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  rescue
    nil
  end
end
