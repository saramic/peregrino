# frozen_string_literal: true

require "net/http"

class NarrativeService
  WIKIPEDIA_BASE = "https://en.wikipedia.org/api/rest_v1/page/summary"
  USER_AGENT     = "Peregrino/0.1 (github.com/saramic/peregrino)"
  OPEN_TIMEOUT   = 3
  READ_TIMEOUT   = 8

  def self.call(lat:, lng:, place: nil, address: nil)
    new(lat:, lng:, place:, address:).call
  end

  def initialize(lat:, lng:, place: nil, address: nil)
    @lat     = lat
    @lng     = lng
    @place   = place
    @address = address
  end

  def call
    unless @place
      locality = LocalityService.call(lat: @lat, lng: @lng)
      return nil unless locality
      @place   = locality[:place]
      @address = locality[:address]
    end

    summary = wikipedia_summary(@place)
    { place: @place, summary: }
  end

  private

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
