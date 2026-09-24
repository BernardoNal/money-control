require "rails_helper"

RSpec.describe Investments::SearchableSelectComponent, type: :component do
  include ViewComponent::TestHelpers
  let(:asset) do
    Investments::Asset.new(id: 42, symbol: "AAPL", name: "Apple Inc.")
  end

  let(:form) do
    ActionView::Helpers::FormBuilder.new(
      "investments_transaction",
      Investments::Transaction.new,
      ActionView::Base.empty,
      {}
    )
  end

  it "renders a generic searchable field with the selected value" do
    render_inline(described_class.new(
      form: form,
      attribute: :asset_id,
      selected: asset,
      selected_label: "AAPL - Apple Inc.",
      search_url: "/search/assets",
      label: "Ativo"
    ))

    expect(page).to have_css("input[type=\"search\"][value=\"AAPL - Apple Inc.\"]")
    expect(page).to have_css("input[name=\"investments_transaction[asset_id]\"][value=\"42\"]", visible: :all)
    expect(page).to have_css("[data-search-url=\"/search/assets\"]")
  end
end
