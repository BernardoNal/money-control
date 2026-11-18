const initializeSearchableSelect = () => {
  document.querySelectorAll("[data-searchable-select]").forEach((root) => {
    if (root.dataset.initialized === "true") return
    root.dataset.initialized = "true"

    const input = root.querySelector("[data-searchable-select-input]")
    const hidden = root.querySelector("[data-searchable-select-value]")
    const results = root.querySelector("[data-searchable-select-results]")
    const error = root.querySelector("[data-searchable-select-error]")
    const suggestion = root.querySelector("[data-searchable-select-suggestion]")
    const form = root.closest("form")
    const searchUrl = root.dataset.searchUrl
    const localOptions = root.dataset.searchableSelectOptions
      ? JSON.parse(root.dataset.searchableSelectOptions).map(([label, value]) => ({ label, value }))
      : null
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
      hidden.value = optionData.id ?? optionData.value
      showError("")
      closeResults()
    }

    // Suggestions come from imported descriptions and remain user-confirmed.
    suggestion?.addEventListener("click", () => {
      const suggestionId = root.dataset.suggestionId
      const suggestionLabel = root.dataset.suggestionLabel
      if (suggestionId && suggestionLabel) selectOption({ id: suggestionId, label: suggestionLabel })
    })

    const renderResults = (options) => {
      results.replaceChildren()
      if (!options.length) {
        const emptyState = document.createElement("p")
        emptyState.className = "px-4 py-3 text-sm text-slate-500"
        emptyState.textContent = localOptions ? "Nenhum banco encontrado." : "Nenhum ativo encontrado."
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

    const renderLocalResults = (query = "") => {
      const normalizedQuery = query.trim().toLocaleLowerCase()
      renderResults(localOptions.filter(({ label, value }) =>
        `${label} ${value}`.toLocaleLowerCase().includes(normalizedQuery)
      ))
    }

    if (localOptions) input.addEventListener("focus", () => renderLocalResults(input.value))

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
      if (localOptions) {
        renderLocalResults(query)
        return
      }

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
          const response = await fetch(`${searchUrl}?${params.toString()}`, { headers: { Accept: "application/json" } })
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
        showError(localOptions ? "Selecione um banco da lista de resultados." : "Selecione um ativo da lista de resultados.")
      }
    })
  })
}

document.addEventListener("turbo:load", initializeSearchableSelect)
