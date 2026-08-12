// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

const buildSubcategoryOptions = (select, options, selectedValue) => {
  const blankOption = document.createElement("option")
  blankOption.value = ""
  blankOption.textContent = "Opcional"
  select.replaceChildren(blankOption)

  options.forEach(([label, value]) => {
    const option = document.createElement("option")
    option.value = value
    option.textContent = label
    option.selected = value === selectedValue
    select.appendChild(option)
  })

  if (selectedValue && !options.some(([, value]) => value === selectedValue)) {
    select.value = ""
  }
}

const initializeAssetSubcategoryFilter = () => {
  const categorySelect = document.querySelector("#investments_asset_category")
  const subcategorySelect = document.querySelector('[data-role="asset-subcategory-select"]')
  if (!categorySelect || !subcategorySelect) return

  const subcategoryMap = JSON.parse(categorySelect.dataset.subcategoryMap || "{}")

  const syncSubcategories = () => {
    const selectedCategory = categorySelect.value
    const currentSubcategory = subcategorySelect.value
    const options = subcategoryMap[selectedCategory] || []
    buildSubcategoryOptions(subcategorySelect, options, currentSubcategory)
    subcategorySelect.disabled = options.length === 0
  }

  syncSubcategories()
  categorySelect.addEventListener("change", syncSubcategories)
}

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

    menu.addEventListener("click", (event) => {
      event.stopPropagation()
    })
  })

  document.addEventListener("click", closeAll)
}

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

    window.setTimeout(() => {
      root.classList.add("hidden", "pointer-events-none")
    }, 200)
  }

  trigger.addEventListener("click", (event) => {
    event.preventDefault()

    if (root.classList.contains("hidden")) {
      openMenu()
    } else {
      closeMenu()
    }
  })

  root.querySelectorAll("[data-mobile-nav-close], [data-mobile-nav-close='true']").forEach((element) => {
    element.addEventListener("click", closeMenu)
  })

  root.querySelectorAll("[data-mobile-nav-close='true']").forEach((element) => {
    element.addEventListener("click", closeMenu)
  })

  backdrop.addEventListener("click", closeMenu)

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !root.classList.contains("hidden")) {
      closeMenu()
    }
  })
}

const initializePortfolioTabs = () => {
  const root = document.querySelector("[data-portfolio-tabs]")
  if (!root || root.dataset.initialized === "true") return

  root.dataset.initialized = "true"

  const hiddenField = document.querySelector('input[name="tab"]')
  const buttons = root.querySelectorAll("[data-tab-button]")
  const panels = document.querySelectorAll("[data-tab-panel]")
  const activeClasses = ["border-[#000080]", "bg-[#000080]", "text-white", "shadow-sm"]
  const inactiveClasses = ["border-slate-300", "bg-white", "text-slate-700", "hover:border-slate-400", "hover:text-slate-950"]

  const setTab = (tab) => {
    panels.forEach((panel) => {
      panel.classList.toggle("hidden", panel.dataset.tabPanel !== tab)
    })

    buttons.forEach((button) => {
      const active = button.dataset.tabButton === tab
      button.classList.remove(...activeClasses, ...inactiveClasses)
      button.classList.add(...(active ? activeClasses : inactiveClasses))
    })

    if (hiddenField) hiddenField.value = tab

    const params = new URLSearchParams(window.location.search)
    params.set("tab", tab)
    const queryString = params.toString()
    const nextUrl = queryString.length > 0 ? `${window.location.pathname}?${queryString}` : window.location.pathname
    window.history.replaceState({}, "", nextUrl)
  }

  buttons.forEach((button) => {
    button.addEventListener("click", () => setTab(button.dataset.tabButton))
  })

  setTab(root.dataset.initialTab || "overview")
}

document.addEventListener("turbo:load", initializeAssetSubcategoryFilter)
document.addEventListener("turbo:load", initializeNavbarDropdowns)
document.addEventListener("turbo:load", initializeMobileNavbar)
document.addEventListener("turbo:load", initializePortfolioTabs)
