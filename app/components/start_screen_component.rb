# frozen_string_literal: true

class StartScreenComponent < ViewComponent::Base
  STATES = %i[initial locating located narrating paused].freeze

  def initialize(preview_state: :initial, location_detail: nil, data_detail: nil)
    @preview_state  = preview_state.to_sym
    @location_detail = location_detail || default_location_detail
    @data_detail     = data_detail     || default_data_detail
  end

  # Steps list
  def steps_hidden?          = @preview_state == :initial

  # CTA / audio controls
  def start_controls_hidden? = %i[narrating paused].include?(@preview_state)
  def audio_controls_hidden? = !start_controls_hidden?

  # Location step
  def location_status
    case @preview_state
    when :locating               then "active"
    when :located, :narrating, :paused then "done"
    else                              "pending"
    end
  end
  def location_detail_hidden? = !%i[located narrating paused].include?(@preview_state)

  # Data step
  def data_step_dim?  = %i[initial locating].include?(@preview_state)
  def data_status
    case @preview_state
    when :located                then "active"
    when :narrating, :paused     then "done"
    else                              "pending"
    end
  end
  def data_detail_hidden? = !%i[narrating paused].include?(@preview_state)

  # Audio step
  def audio_step_dim? = %i[initial locating located].include?(@preview_state)
  def audio_status    = %i[narrating paused].include?(@preview_state) ? "active" : "pending"

  # Pause / Resume button
  def paused?              = @preview_state == :paused
  def pause_label          = paused? ? "Resume" : "Pause"
  def pause_icon_hidden?   = paused?
  def play_icon_hidden?    = !paused?

  private

  def default_location_detail
    %i[located narrating paused].include?(@preview_state) ? "-33.8688, 151.2093  ·  GPS" : nil
  end

  def default_data_detail
    %i[narrating paused].include?(@preview_state) ? "Sydney" : nil
  end
end
