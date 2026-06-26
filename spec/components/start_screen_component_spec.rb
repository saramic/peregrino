# frozen_string_literal: true

require "rails_helper"

RSpec.describe StartScreenComponent, type: :component do
  before { render_inline(described_class.new) }

  it "renders the Peregrino wordmark" do
    expect(page).to have_css("[data-testid='wordmark']", text: "Peregrino")
  end

  it "renders a start button" do
    expect(page).to have_css("[data-testid='start-button']")
  end
end
