class Screens::StartScreenComponentPreview < Lookbook::Preview
  layout "component_preview"

  def default
    render StartScreenComponent.new
  end
end
