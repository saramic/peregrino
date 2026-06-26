# frozen_string_literal: true

module GeolocationHelpers
  # Call after page.load, before the button click.
  def grant_browser_geolocation(lat:, lng:)
    page.execute_script(<<~JS)
      navigator.geolocation.getCurrentPosition = function(success) {
        success({ coords: { latitude: #{lat}, longitude: #{lng}, accuracy: 10 } })
      }
    JS
  end

  def deny_browser_geolocation
    page.execute_script(<<~JS)
      navigator.geolocation.getCurrentPosition = function(_success, error) {
        error({ code: 1, message: "User denied geolocation" })
      }
    JS
  end

  def stub_ip_geolocation(lat:, lng:)
    allow(IpGeolocationService).to receive(:call).and_return({ lat: lat, lng: lng })
  end

  def stub_ip_geolocation_unavailable
    allow(IpGeolocationService).to receive(:call).and_return(nil)
  end
end

RSpec.configure do |config|
  config.include GeolocationHelpers, type: :feature
end
