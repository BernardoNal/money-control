const initializeNavbarDropdowns = () => {
  const dropdowns = document.querySelectorAll("[data-dropdown]")
  if (!dropdowns.length) return

  const closeAll = () => {
    dropdowns.forEach((dropdown) => {
      const trigger = dropdown.querySelector("[data-dropdown-trigger]")
      const menu = dropdown.querySelector("[data-dropdown-menu]")
      if (!trigger || !menu) return

      trigger.setAttribute("aria-expanded", "false")
      menu.classList.add("hidden")
    })
  }

  dropdowns.forEach((dropdown) => {
    const trigger = dropdown.querySelector("[data-dropdown-trigger]")
    const menu = dropdown.querySelector("[data-dropdown-menu]")
    if (!trigger || !menu) return

    trigger.addEventListener("click", (event) => {
      event.preventDefault()
      event.stopPropagation()

      const isOpen = !menu.classList.contains("hidden")
      closeAll()
      if (!isOpen) {
        trigger.setAttribute("aria-expanded", "true")
        menu.classList.remove("hidden")
      }
    })

    menu.addEventListener("click", (event) => event.stopPropagation())
  })

  document.addEventListener("click", closeAll)
}

document.addEventListener("turbo:load", initializeNavbarDropdowns)
