# frozen_string_literal: true

module NarrativeHelpers
  def stub_locality(place:)
    allow(LocalityService).to receive(:call).and_return({ place:, address: {} })
  end

  def stub_locality_unavailable
    allow(LocalityService).to receive(:call).and_return(nil)
  end

  def stub_narrative(place:, summary:)
    stub_locality(place:)
    allow(NarrativeService).to receive(:call).and_return({ place:, summary: })
  end

  def stub_narrative_unavailable
    stub_locality_unavailable
    allow(NarrativeService).to receive(:call).and_return(nil)
  end

  # Injects a silent SpeechSynthesis mock into the page.
  # Uses Object.defineProperty so it works even when speechSynthesis is read-only.
  # Call after page.load, before the action that triggers speech.
  def stub_speech_synthesis
    page.execute_script(<<~JS)
      window.SpeechSynthesisUtterance = function(text) { this.text = text }
      Object.defineProperty(window, 'speechSynthesis', {
        value: {
          speak:   function(u) { window._lastUtterance = u },
          pause:   function()  { window._synthPaused = true },
          resume:  function()  { window._synthPaused = false },
          cancel:  function()  { window._lastUtterance = null }
        },
        writable: true,
        configurable: true
      })
    JS
  end
end

RSpec.configure do |config|
  config.include NarrativeHelpers, type: :feature
end
