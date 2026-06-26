# frozen_string_literal: true

class ActionButtonComponent < ViewComponent::Base
  def initialize(label:, variant: :primary, loading: false, icons: true, reset_after: nil)
    @label = label
    @variant = variant
    @loading = loading
    @icons = icons
    @reset_after = reset_after
  end

  private

  def css_classes
    base = "group inline-flex items-center justify-center gap-3 rounded-full px-8 py-4 text-base font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-60"
    case @variant
    when :primary   then "#{base} bg-brand text-canvas hover:brightness-110 active:brightness-95"
    when :secondary then "#{base} border border-muted/50 text-muted hover:border-muted hover:text-prose"
    else base
    end
  end
end
