# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActionButtonComponent, type: :component do
  it "renders a primary button" do
    render_inline(described_class.new(label: "Start"))
    expect(page).to have_button("Start")
  end

  it "renders a secondary button" do
    render_inline(described_class.new(label: "Skip", variant: :secondary))
    expect(page).to have_button("Skip")
  end
end
