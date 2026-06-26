# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Fast start from landing page to live commentary", :js do
  let(:start_screen) { Pages::StartScreen.new }

  it "Start speaking after location is granted" do
    When "user visits the app" do
      start_screen.load
    end

    And "hits start" do
      start_screen.start
    end
  end
end
