# frozen_string_literal: true

require "net/http"

class IpGeolocationService
  URL = URI("https://ipapi.co/json/")

  def self.call
    response = Net::HTTP.get(URL)
    data     = JSON.parse(response)
    return nil unless data["latitude"] && data["longitude"]

    { lat: data["latitude"].to_f, lng: data["longitude"].to_f }
  rescue
    nil
  end
end
