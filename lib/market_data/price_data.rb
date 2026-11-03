module MarketData
  PriceData = Struct.new(
    :symbol,
    :price,
    :currency,
    :as_of,
    keyword_init: true
  )

  HistoricalPriceData = Struct.new(
    :symbol,
    :price,
    :currency,
    :as_of,
    keyword_init: true
  )
end
