# frozen_string_literal: true

require "net/http"

class IpGeolocationService
  URL          = URI("https://ipapi.co/json/")
  OPEN_TIMEOUT = 3
  READ_TIMEOUT = 5

  def self.call
    req = Net::HTTP::Get.new(URL)
    req["Accept"] = "application/json"
    res = Net::HTTP.start(URL.host, URL.port,
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
