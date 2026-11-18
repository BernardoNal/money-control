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
      rows.forEach((checkbox) => { checkbox.checked = selectAll.checked })
      syncSelectAll()
    })
    rows.forEach((checkbox) => checkbox.addEventListener("change", syncSelectAll))
    syncSelectAll()
  })
}

document.addEventListener("turbo:load", initializeIncomeImportSelection)
