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

document.addEventListener("turbo:load", initializeAssetSubcategoryFilter)
document.addEventListener("turbo:load", initializeNavbarDropdowns)
