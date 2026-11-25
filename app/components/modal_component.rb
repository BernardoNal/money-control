# frozen_string_literal: true

class ModalComponent < ViewComponent::Base
  SIZES = {
    sm: "max-w-lg",
    md: "max-w-2xl",
    lg: "max-w-5xl",
    xl: "max-w-7xl"
  }.freeze

  def initialize(id:, title:, size: :lg, close_label: "Fechar modal", open: false, clear_params: [])
    @id = id
    @title = title
    @size = size.to_sym
    @close_label = close_label
    @open = open
    @clear_params = Array(clear_params).map(&:to_s)
  end

  attr_reader :id, :title, :close_label, :clear_params

  def open?
    @open
  end

  def dialog_classes
    ["m-auto w-[calc(100%-2rem)] max-h-[90vh] overflow-y-auto rounded-3xl border border-slate-300 bg-white p-0 text-slate-950 shadow-2xl backdrop:bg-slate-950/40", SIZES.fetch(@size, SIZES[:lg])].join(" ")
  end

  def title_id
    "#{id}-title"
  end
end
