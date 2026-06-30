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

  it "shows a progress list with step states after tapping Start" do
    stub_ip_geolocation(lat: -33.8688, lng: 151.2093)
    stub_locality(place: "Sydney")

    When "user visits the app" do
      start_screen.load
    end

    And "the browser grants GPS location" do
      grant_browser_geolocation(lat: -33.8688, lng: 151.2093)
    end

    And "user taps Start" do
      start_screen.start
    end

    Then "the progress list appears" do
      expect(page).to have_css("[data-testid='journey-steps']")
    end

    And "the location step is marked complete with coordinates" do
      expect(page).to have_css("[data-journey-target='locationIcon'][data-status='done']")
      expect(page).to have_text("-33.8688")
    end

    And "the topic step shows the resolved locality" do
      expect(page).to have_css("[data-journey-target='topicIcon'][data-status='done']")
      expect(page).to have_text("Sydney")
    end

    And "the data step becomes active" do
      expect(page).to have_css("[data-journey-target='dataIcon'][data-status='active']")
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

  it "fetches a narrative and queues audio after location is resolved" do
    stub_narrative(
      place: "Sydney",
      summary: "Sydney is the capital city of New South Wales."
    )

    When "user visits the app" do
      start_screen.load
    end

    And "the browser grants GPS and speech is mocked" do
      grant_browser_geolocation(lat: -33.8688, lng: 151.2093)
      stub_speech_synthesis
    end

    And "user taps Start" do
      start_screen.start
    end

    Then "the topic step completes and shows the place name" do
      expect(page).to have_css("[data-journey-target='topicIcon'][data-status='done']")
      expect(page).to have_text("Sydney")
    end

    And "the data step completes" do
      expect(page).to have_css("[data-journey-target='dataIcon'][data-status='done']")
    end

    And "the audio step becomes active" do
      expect(page).to have_css("[data-journey-target='audioIcon'][data-status='active']")
    end

    And "the narrative text is queued for speech" do
      expect(page).to have_css("[data-controller='journey'][data-pending-narrative*='capital city']")
    end

    And "the Start button is replaced by audio controls" do
      expect(page).to have_no_css("[data-testid='start-button']", visible: :visible)
      expect(page).to have_css("[data-testid='audio-controls']", visible: :visible)
      expect(page).to have_button("Pause")
      expect(page).to have_button("Restart")
    end
  end

  it "pauses and resumes the narrative" do
    stub_narrative(
      place: "Sydney",
      summary: "Sydney is the capital city of New South Wales."
    )

    When "user visits the app" do
      start_screen.load
    end

    And "the browser grants GPS and speech is mocked" do
      grant_browser_geolocation(lat: -33.8688, lng: 151.2093)
      stub_speech_synthesis
    end

    And "user taps Start and audio controls appear" do
      start_screen.start
      expect(page).to have_button("Pause")
    end

    When "user taps Pause" do
      click_button "Pause"
    end

    Then "the button changes to Resume" do
      expect(page).to have_button("Resume")
      expect(page).to have_no_button("Pause")
    end

    When "user taps Resume" do
      click_button "Resume"
    end

    Then "the button changes back to Pause" do
      expect(page).to have_button("Pause")
      expect(page).to have_no_button("Resume")
    end
  end

  it "reloads the start screen when Restart is tapped" do
    stub_narrative(
      place: "Sydney",
      summary: "Sydney is the capital city of New South Wales."
    )

    When "user visits the app" do
      start_screen.load
    end

    And "the browser grants GPS and speech is mocked" do
      grant_browser_geolocation(lat: -33.8688, lng: 151.2093)
      stub_speech_synthesis
    end

    And "user taps Start and audio controls appear" do
      start_screen.start
      expect(page).to have_button("Restart")
    end

    When "user taps Restart" do
      click_button "Restart"
    end

    Then "the start screen is shown again with no progress list" do
      expect(page).to have_css("[data-testid='start-button']", visible: :visible)
      expect(page).to have_no_css("[data-testid='audio-controls']", visible: :visible)
      expect(page).to have_no_css("[data-testid='journey-steps']", visible: :visible)
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
