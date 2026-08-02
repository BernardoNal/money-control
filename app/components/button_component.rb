# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  VARIANT_STYLES = {
    primary: "whitespace-nowrap inline-flex items-center justify-center gap-2 rounded-full bg-[#000080] px-5 py-3 text-sm font-semibold text-white no-underline transition hover:bg-[#000066] focus:outline-none focus:ring-4 focus:ring-blue-200",
    soft_olive: "inline-flex items-center gap-2 rounded-full border border-[#808000]/40 bg-[#808000]/10 px-5 py-3 text-sm font-medium text-[#808000] no-underline transition hover:bg-[#808000]/20 hover:text-[#6b6b00]",
    danger: "inline-flex items-center justify-center gap-2 rounded-full bg-rose-600 px-5 py-3 text-sm font-semibold text-white no-underline transition hover:bg-rose-700 focus:outline-none focus:ring-4 focus:ring-rose-200"
  }.freeze

  def initialize(label:, href: nil, variant: :primary, icon: nil, method: nil, data: {}, type: :button, classes: nil)
    @label = label
    @href = href
    @variant = variant.to_sym
    @icon = icon
    @method = method
    @data = data
    @type = type
    @classes = classes
  end

  attr_reader :label, :href, :icon, :method, :data, :type

  def link?
    href.present?
  end

  def css_classes
    [VARIANT_STYLES.fetch(@variant, VARIANT_STYLES[:primary]), @classes].compact.join(" ")
  end
end
