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

document.addEventListener("turbo:load", initializeAssetSubcategoryFilter)
