const initializeModalDialogs = () => {
  document.querySelectorAll("[data-modal]").forEach((dialog) => {
    if (dialog.dataset.modalInitialized === "true") return
    dialog.dataset.modalInitialized = "true"

    const triggers = document.querySelectorAll(`[data-modal-target="${dialog.id}"]`)
    let lastFocusedElement

    const openModal = (event) => {
      event?.preventDefault()
      lastFocusedElement = event?.currentTarget || document.activeElement
      dialog.showModal()
    }

    const closeModal = () => dialog.close()

    triggers.forEach((trigger) => trigger.addEventListener("click", openModal))
    dialog.querySelectorAll("[data-modal-close]").forEach((closeButton) => closeButton.addEventListener("click", closeModal))
    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) closeModal()
    })
    dialog.addEventListener("close", () => lastFocusedElement?.focus())
  })
}

document.addEventListener("turbo:load", initializeModalDialogs)

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
