# frozen_string_literal: true

module Investments
  class SearchableSelectComponent < ViewComponent::Base
    def initialize(form:, attribute:, selected:, search_url:, label:, selected_label: nil, placeholder: "Busque para selecionar", search_params: {})
      @form = form
      @attribute = attribute
      @selected = selected
      @search_url = search_url
      @label = label
      @selected_label = selected_label
      @placeholder = placeholder
      @search_params = search_params
    end

    attr_reader :form, :attribute, :selected, :search_url, :label, :placeholder, :search_params

    def input_id
      "#{form.object_name.to_s.gsub(/[^a-zA-Z0-9_-]/, "_")}_#{attribute}_search"
    end

    def selected_id
      selected&.id
    end

    def selected_text
      selected_label.to_s
    end

    private

    attr_reader :selected_label
  end
end
