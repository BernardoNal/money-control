module TransactionsHelper
  # Default direction categories are implementation placeholders, not useful
  # labels in a transaction summary.
  def transaction_category_label(category)
    name = category&.name.to_s
    return "--" if name.blank? || name.match?(/\ASem categoria \((?:Entrada|Saída)\)\z/)

    name
  end
end
