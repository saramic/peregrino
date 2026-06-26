class ButtonComponentPreview < Lookbook::Preview
  layout "component_preview"

  def default
    render ButtonComponent.new(label: "Start", variant: :primary)
  end

  def secondary
    render ButtonComponent.new(label: "Skip", variant: :secondary)
  end
end
