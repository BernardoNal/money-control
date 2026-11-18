const initializeMobileNavbar = () => {
  const root = document.querySelector("[data-mobile-nav-root]")
  const trigger = document.querySelector("[data-mobile-nav-trigger]")
  const sidebar = document.querySelector("#mobile-sidebar")
  const backdrop = document.querySelector("[data-mobile-nav-backdrop]")
  if (!root || !trigger || !sidebar || !backdrop) return

  const openMenu = () => {
    root.classList.remove("hidden", "pointer-events-none")
    trigger.setAttribute("aria-expanded", "true")
    sidebar.setAttribute("aria-hidden", "false")
    requestAnimationFrame(() => {
      backdrop.classList.remove("opacity-0")
      sidebar.classList.remove("-translate-x-full")
    })
  }

  const closeMenu = () => {
    trigger.setAttribute("aria-expanded", "false")
    sidebar.setAttribute("aria-hidden", "true")
    backdrop.classList.add("opacity-0")
    sidebar.classList.add("-translate-x-full")
    window.setTimeout(() => root.classList.add("hidden", "pointer-events-none"), 200)
  }

  trigger.addEventListener("click", (event) => {
    event.preventDefault()
    root.classList.contains("hidden") ? openMenu() : closeMenu()
  })
  root.querySelectorAll("[data-mobile-nav-close], [data-mobile-nav-close='true']").forEach((element) => {
    element.addEventListener("click", closeMenu)
  })
  backdrop.addEventListener("click", closeMenu)
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !root.classList.contains("hidden")) closeMenu()
  })
}

document.addEventListener("turbo:load", initializeMobileNavbar)
