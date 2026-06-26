# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  def initialize(label:, variant: :primary)
    @label = label
    @variant = variant
  end

  private

  def css_classes
    base = "inline-flex items-center justify-center rounded-full px-8 py-4 text-base font-semibold transition-colors"
    case @variant
    when :primary   then "#{base} bg-brand text-canvas hover:brightness-110 active:brightness-95"
    when :secondary then "#{base} border border-muted/50 text-muted hover:border-muted hover:text-prose"
    else base
    end
  end
end
