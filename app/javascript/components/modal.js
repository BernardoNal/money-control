const initializeTransactionDialogs = () => {
  document.querySelectorAll("[data-transaction-dialog]").forEach((dialog) => {
    if (dialog.dataset.initialized === "true") return
    dialog.dataset.initialized = "true"

    const opener = document.querySelector(`[data-transaction-dialog-target="${dialog.id}"]`)
    let lastFocusedElement
    opener?.addEventListener("click", () => {
      lastFocusedElement = document.activeElement
      dialog.showModal()
    })
    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) dialog.close()
    })
    dialog.addEventListener("close", () => lastFocusedElement?.focus())
  })
}

document.addEventListener("turbo:load", initializeTransactionDialogs)
