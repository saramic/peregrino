# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Starting a journey", :js do
  let(:start_screen) { Pages::StartScreen.new }

  it "shows a start screen with a single call to action" do
    When "user visits the app" do
      start_screen.load
    end

    Then "user sees the Peregrino wordmark and a start button" do
      expect(start_screen).to have_wordmark
      expect(start_screen).to have_start_button
    end
  end

  it "displays GPS coordinates when the user grants location" do
    When "user visits the app" do
      start_screen.load
    end

    And "the browser grants GPS location" do
      grant_browser_geolocation(lat: -33.8688, lng: 151.2093)
    end

    And "user taps Start" do
      start_screen.start
    end

    Then "user sees their GPS coordinates" do
      expect(page).to have_text("-33.8688")
      expect(page).to have_text("151.2093")
      expect(page).to have_text("GPS")
    end
  end

  it "falls back to IP geolocation when GPS is denied" do
    stub_ip_geolocation(lat: -27.4698, lng: 153.0251)

    When "user visits the app" do
      start_screen.load
    end

    And "the browser denies GPS location" do
      deny_browser_geolocation
    end

    And "user taps Start" do
      start_screen.start
    end

    Then "user sees their IP-derived coordinates" do
      expect(page).to have_text("-27.4698")
      expect(page).to have_text("153.0251")
      expect(page).to have_text("IP")
    end
  end

  it "falls back to Melbourne when GPS is denied and IP lookup fails" do
    stub_ip_geolocation_unavailable

    When "user visits the app" do
      start_screen.load
    end

    And "the browser denies GPS location" do
      deny_browser_geolocation
    end

    And "user taps Start" do
      start_screen.start
    end

    Then "user sees the Melbourne fallback coordinates" do
      expect(page).to have_text("-37.8136")
      expect(page).to have_text("144.9631")
      expect(page).to have_text("Melbourne default")
    end
  end
end
