# frozen_string_literal: true

require "rails_helper"

RSpec.feature "It works root rails demo page", :js, type: :feature do
  scenario "I have rails" do
    When "user visits the app" do
      visit test_root_rails_path
    end

    Then "user sees they are on rails" do
      expect(
        find("ul li", text: "Rails version")
      ).to have_text "Rails version: 8.1.3"

      expect(
        find("ul li", text: "Ruby version")
      ).to have_text "Ruby version: ruby 4.0.5"
    end
  end
end
