module MarketData
  AssetData = Struct.new(
    :symbol,
    :name,
    :currency,
    :category,
    :subcategory,
    :active,
    keyword_init: true
  )
end
