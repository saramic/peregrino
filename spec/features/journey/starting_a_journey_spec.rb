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
end
