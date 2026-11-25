require "rails_helper"

RSpec.describe ModalComponent, type: :component do
  include ViewComponent::TestHelpers

  it "renders an accessible reusable dialog with its content" do
    render_inline(described_class.new(id: "transaction-modal", title: "Detalhes da transação")) do
      "Conteúdo da transação"
    end

    expect(page).to have_css("dialog[data-modal][aria-modal='true']#transaction-modal")
    expect(page).to have_css("h2#transaction-modal-title", text: "Detalhes da transação")
    expect(page).to have_css("[data-modal-close][aria-label='Fechar modal']")
    expect(page).to have_text("Conteúdo da transação")
  end

  it "supports a constrained modal size" do
    render_inline(described_class.new(id: "small-modal", title: "Modal pequeno", size: :sm))

    expect(page).to have_css("dialog.max-w-lg")
  end

  it "declares query parameters to clear when the modal closes" do
    render_inline(described_class.new(id: "income-modal", title: "Detalhes", clear_params: %w[modal income_id]))

    expect(page).to have_css("dialog[data-modal-clear-params='modal,income_id']")
  end
end
