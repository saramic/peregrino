# frozen_string_literal: true

require "net/http"

class IpGeolocationService
  BASE_URL     = "https://ipapi.co"
  OPEN_TIMEOUT = 3
  READ_TIMEOUT = 5

  def self.call(ip: nil)
    path = ip.present? ? "/#{ip}/json/" : "/json/"
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Get.new(uri)
    req["Accept"] = "application/json"
    res = Net::HTTP.start(uri.host, uri.port,
      use_ssl: true,
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    ) { |h| h.request(req) }
    return nil unless res.is_a?(Net::HTTPSuccess)

    data = JSON.parse(res.body)
    return nil unless data["latitude"] && data["longitude"]

    { lat: data["latitude"].to_f, lng: data["longitude"].to_f }
  rescue
    nil
  end
end
