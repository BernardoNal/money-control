const initializeTransactionForm = () => {
  const amountField = document.querySelector("#transaction_amount")
  const categorySelect = document.querySelector("[data-transaction-category-select]")
  const paymentMethodSelect = document.querySelector("[data-payment-method-select]")
  const paymentMethodOther = document.querySelector("[data-payment-method-other]")
  if (!amountField || !categorySelect) return

  const syncCategories = () => {
    const amount = Number.parseFloat(amountField.value.replace(",", "."))
    if (Number.isNaN(amount)) return

    const income = amount >= 0
    Array.from(categorySelect.options).forEach((option) => {
      option.hidden = option.value !== "" && option.dataset.income !== String(income)
    })
    const selected = categorySelect.selectedOptions[0]
    if (selected && selected.value !== "" && selected.dataset.income !== String(income)) categorySelect.value = ""
  }

  const syncOtherPaymentMethod = () => {
    if (!paymentMethodSelect || !paymentMethodOther) return
    const isOther = paymentMethodSelect.value === "Outro"
    paymentMethodOther.classList.toggle("hidden", !isOther)
    paymentMethodOther.disabled = !isOther
  }

  amountField.addEventListener("input", syncCategories)
  paymentMethodSelect?.addEventListener("change", syncOtherPaymentMethod)
  syncCategories()
  syncOtherPaymentMethod()
}

document.addEventListener("turbo:load", initializeTransactionForm)
