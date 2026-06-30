# frozen_string_literal: true

require "net/http"

class NarrativeService
  NOMINATIM_BASE = "https://nominatim.openstreetmap.org"
  WIKIPEDIA_BASE = "https://en.wikipedia.org/api/rest_v1/page/summary"
  USER_AGENT     = "Peregrino/0.1 (github.com/saramic/peregrino)"

  def self.call(lat:, lng:)
    new(lat:, lng:).call
  end

  def initialize(lat:, lng:)
    @lat = lat
    @lng = lng
  end

  def call
    place = reverse_geocode
    return nil unless place

    summary = wikipedia_summary(place)
    { place:, summary: }
  end

  private

  def reverse_geocode
    uri = URI("#{NOMINATIM_BASE}/reverse?lat=#{@lat}&lon=#{@lng}&format=json")
    data = fetch_json(uri)
    return nil unless data

    @address = data["address"] || {}
    @address["city"]          ||
      @address["town"]        ||
      @address["village"]     ||
      @address["hamlet"]      ||
      @address["locality"]    ||
      @address["suburb"]      ||
      @address["municipality"] ||
      @address["county"]      ||
      data["name"].presence
  end

  def wikipedia_summary(place)
    place_candidates(place).each do |candidate|
      encoded = URI.encode_www_form_component(candidate)
      data = fetch_json(URI("#{WIKIPEDIA_BASE}/#{encoded}"))
      extract = data&.fetch("extract", nil)
      return extract if extract.present?
    end
    nil
  end

  def place_candidates(place)
    addr = @address || {}
    [
      place,
      addr["suburb"],
      addr["municipality"],
      addr["county"],
      addr["state_district"],
      addr["state"]
    ].compact.uniq
  end

  def fetch_json(uri)
    req = Net::HTTP::Get.new(uri)
    req["User-Agent"] = USER_AGENT
    req["Accept"]     = "application/json"
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |h| h.request(req) }
    return nil unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  rescue
    nil
  end
end
