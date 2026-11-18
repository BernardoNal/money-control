const initializeImportReview = () => {
  const form = document.querySelector("[data-import-review-form]")
  if (!form || form.dataset.initialized === "true") return

  form.dataset.initialized = "true"
  const confirmButton = form.querySelector("[data-import-review-confirm]")
  const resetButton = form.querySelector("[data-import-review-reset]")
  const stateLabel = form.querySelector("[data-import-review-state]")

  const setDirty = (dirty) => {
    if (confirmButton) confirmButton.disabled = dirty
    if (stateLabel) stateLabel.textContent = dirty ? "Salve as alterações para confirmar." : "Alterações salvas."
  }

  form.addEventListener("input", () => setDirty(true))
  form.addEventListener("change", () => setDirty(true))
  resetButton?.addEventListener("click", () => {
    form.reset()
    setDirty(false)
  })
}

document.addEventListener("turbo:load", initializeImportReview)
