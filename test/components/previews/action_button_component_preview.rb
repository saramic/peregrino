class ActionButtonComponentPreview < Lookbook::Preview
  layout "component_preview"

  # Click to see arrow become spinner — resets after 3 seconds
  def default
    render ActionButtonComponent.new(label: "Start", reset_after: 3000)
  end

  # Pre-rendered in loading state
  def loading
    render ActionButtonComponent.new(label: "Start", loading: true)
  end

  # Label only — no icons
  def plain
    render ActionButtonComponent.new(label: "Start", icons: false)
  end

  def secondary
    render ActionButtonComponent.new(label: "Skip", variant: :secondary, reset_after: 3000)
  end
end
