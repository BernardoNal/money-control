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
      const matches = option.value === "" || option.dataset.income === String(income)
      option.hidden = !matches
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

document.addEventListener("turbo:load", initializeAssetSubcategoryFilter)
document.addEventListener("turbo:load", initializeNavbarDropdowns)
document.addEventListener("turbo:load", initializeMobileNavbar)
document.addEventListener("turbo:load", initializePortfolioTabs)
document.addEventListener("turbo:load", initializeImportReview)
document.addEventListener("turbo:load", initializeTransactionForm)

const initializeSearchableSelect = () => {
  document.querySelectorAll("[data-searchable-select]").forEach((root) => {
    if (root.dataset.initialized === "true") return
    root.dataset.initialized = "true"

    const input = root.querySelector("[data-searchable-select-input]")
    const hidden = root.querySelector("[data-searchable-select-value]")
    const results = root.querySelector("[data-searchable-select-results]")
    const error = root.querySelector("[data-searchable-select-error]")
    const form = root.closest("form")
    const searchUrl = root.dataset.searchUrl
    let timer
    let requestId = 0

    const closeResults = () => {
      results.replaceChildren()
      results.classList.add("hidden")
      input.setAttribute("aria-expanded", "false")
    }

    const showError = (message) => {
      error.textContent = message
      error.classList.toggle("hidden", !message)
    }

    const selectOption = (optionData) => {
      input.value = optionData.label
      hidden.value = optionData.id
      showError("")
      closeResults()
    }

    const renderResults = (options) => {
      results.replaceChildren()
      if (!options.length) {
        const emptyState = document.createElement("p")
        emptyState.className = "px-4 py-3 text-sm text-slate-500"
        emptyState.textContent = "Nenhum ativo encontrado."
        results.appendChild(emptyState)
        results.classList.remove("hidden")
        input.setAttribute("aria-expanded", "true")
        return
      }

      options.forEach((optionData) => {
        const option = document.createElement("button")
        option.type = "button"
        option.setAttribute("role", "option")
        option.className = "block w-full px-4 py-3 text-left text-sm hover:bg-slate-100"
        option.textContent = optionData.label
        option.addEventListener("click", () => selectOption(optionData))
        results.appendChild(option)
      })
      results.classList.remove("hidden")
      input.setAttribute("aria-expanded", "true")
    }

    input.addEventListener("keydown", (event) => {
      if (event.key === "Escape") closeResults()
      if (event.key === "ArrowDown") {
        const firstOption = results.querySelector("button[role=\"option\"]")
        if (firstOption) {
          event.preventDefault()
          firstOption.focus()
        }
      }
    })

    input.addEventListener("input", () => {
      hidden.value = ""
      showError("")
      window.clearTimeout(timer)
      const query = input.value.trim()
      results.textContent = "Buscando ativos..."
      results.classList.remove("hidden")
      input.setAttribute("aria-expanded", "true")
      if (query.length < 2) {
        closeResults()
        return
      }

      timer = window.setTimeout(async () => {
        const currentRequest = ++requestId
        const params = new URLSearchParams({ q: query })
        const searchParams = JSON.parse(root.dataset.searchParams || "{}")
        Object.entries(searchParams).forEach(([key, value]) => params.set(key, value))

        try {
          const response = await fetch(`${searchUrl}?${params.toString()}`, {
            headers: { Accept: "application/json" }
          })
          if (!response.ok) throw new Error("asset search failed")
          const assets = await response.json()
          if (currentRequest === requestId) renderResults(assets)
        } catch (_error) {
          if (currentRequest === requestId) {
            closeResults()
            showError("Não foi possível buscar os ativos.")
          }
        }
      }, 250)
    })

    form.addEventListener("submit", (event) => {
      if (input.value.trim() && !hidden.value) {
        event.preventDefault()
        showError("Selecione um ativo da lista de resultados.")
      }
    })
  })
}

document.addEventListener("turbo:load", initializeSearchableSelect)

const initializeIncomeImportSelection = () => {
  document.querySelectorAll("[data-income-import-select-all]").forEach((selectAll) => {
    if (selectAll.dataset.initialized === "true") return
    selectAll.dataset.initialized = "true"

    const form = selectAll.closest("form")
    const rows = Array.from(form.querySelectorAll("[data-income-import-row]"))
      .filter((checkbox) => !checkbox.disabled)

    const syncSelectAll = () => {
      const selectedCount = rows.filter((checkbox) => checkbox.checked).length
      selectAll.checked = rows.length > 0 && selectedCount === rows.length
      selectAll.indeterminate = selectedCount > 0 && selectedCount < rows.length
    }

    selectAll.addEventListener("change", () => {
      rows.forEach((checkbox) => {
        checkbox.checked = selectAll.checked
      })
      syncSelectAll()
    })

    rows.forEach((checkbox) => checkbox.addEventListener("change", syncSelectAll))
    syncSelectAll()
  })
}

document.addEventListener("turbo:load", initializeIncomeImportSelection)
