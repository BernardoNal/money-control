require "rails_helper"

RSpec.describe SearchFieldComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:form) do
    ActionView::Helpers::FormBuilder.new(
      "investments_asset",
      Investments::Asset.new,
      ActionView::Base.empty,
      {}
    )
  end

  it "renders a search field with its label, value, and placeholder" do
    render_inline(described_class.new(
      form: form,
      attribute: :q,
      value: "Apple",
      label: "Buscar ativo",
      placeholder: "Nome ou ticker"
    ))

    expect(page).to have_css("label[for=\"investments_asset_q\"]", text: "Buscar ativo")
    expect(page).to have_css("input[type=\"search\"][name=\"investments_asset[q]\"][value=\"Apple\"][placeholder=\"Nome ou ticker\"]")
  end
end
