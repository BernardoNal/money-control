# frozen_string_literal: true

class SearchFieldComponent < ViewComponent::Base
  def initialize(form:, attribute:, value:, label:, placeholder: nil)
    @form = form
    @attribute = attribute
    @value = value
    @label = label
    @placeholder = placeholder
  end

  attr_reader :form, :attribute, :value, :label, :placeholder
end
