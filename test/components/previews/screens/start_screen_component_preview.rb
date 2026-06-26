class Screens::StartScreenComponentPreview < Lookbook::Preview
  layout "component_preview"

  # Initial landing page — Start button, no progress list
  def default
    render StartScreenComponent.new
  end

  # Resolving location — spinner on the location step
  def locating
    render StartScreenComponent.new(preview_state: :locating)
  end

  # Location found — coordinates shown, fetching data spinner active
  def located
    render StartScreenComponent.new(preview_state: :located)
  end

  # Narrative fetched, speaking — audio controls replace Start button
  def narrating
    render StartScreenComponent.new(preview_state: :narrating)
  end

  # Speech paused — Resume button and play icon shown
  def paused
    render StartScreenComponent.new(preview_state: :paused)
  end
end
