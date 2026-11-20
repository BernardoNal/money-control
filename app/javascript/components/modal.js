const initializeModalDialogs = () => {
  document.querySelectorAll("[data-modal]").forEach((dialog) => {
    if (dialog.dataset.modalInitialized === "true") return
    dialog.dataset.modalInitialized = "true"

    const triggers = document.querySelectorAll(`[data-modal-target="${dialog.id}"]`)
    let lastFocusedElement

    const openModal = (event) => {
      event?.preventDefault()
      lastFocusedElement = event?.currentTarget || triggers[0] || document.activeElement
      if (!dialog.open) dialog.showModal()
      dialog.querySelector("[data-modal-close]")?.focus()
    }

    const closeModal = () => dialog.close()

    triggers.forEach((trigger) => trigger.addEventListener("click", openModal))
    dialog.querySelectorAll("[data-modal-close]").forEach((closeButton) => closeButton.addEventListener("click", closeModal))
    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) closeModal()
    })
    dialog.addEventListener("close", () => lastFocusedElement?.focus())

    if (dialog.dataset.modalOpen === "true") openModal()
  })
}

document.addEventListener("turbo:load", initializeModalDialogs)
