# frozen_string_literal: true

require "rails_helper"

RSpec.feature "It works root rails demo page", :js do
  let(:it_works_root) { Pages::ItWorksRoot.new }

  it "I have rails" do
    When "user visits the app" do
      it_works_root.load
    end

    Then "user sees they are on rails" do
      expect(it_works_root.rails_version.text).to match(/8.1.3/)
      expect(it_works_root.ruby_version.text).to match(/ruby 4.0.5/)
    end
  end
end
