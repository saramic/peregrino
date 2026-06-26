# frozen_string_literal: true

module Pages
  class StartScreen < SitePrism::Page
    set_url Rails.application.routes.url_helpers.root_path

    element :wordmark, "[data-testid='wordmark']"
    element :start_button, "[data-testid='start-button'] button"
    element :journey_steps, "[data-testid='journey-steps']"

    def start
      start_button.click
    end
  end
end
