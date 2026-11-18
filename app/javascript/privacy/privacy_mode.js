const PRIVACY_MODE_STORAGE_KEY = "money-control:privacy-mode"

const initializePrivacyMode = () => {
  const toggles = document.querySelectorAll("[data-privacy-toggle]")
  if (!toggles.length) return

  const applyPrivacyMode = (isHidden) => {
    document.documentElement.dataset.privacyMode = isHidden ? "hidden" : "visible"

    document.querySelectorAll("[data-sensitive-value]").forEach((element) => {
      const visibleValue = element.dataset.sensitiveVisibleValue || element.textContent
      const maskedValue = element.dataset.sensitiveMaskedValue || "••••••"
      element.textContent = isHidden ? maskedValue : visibleValue
      element.setAttribute("aria-label", isHidden ? "Valor financeiro oculto" : visibleValue)
    })

    // Chart labels and SVG titles need the same masking treatment as regular financial values.
    document.querySelectorAll("[data-sensitive-chart-value]").forEach((element) => {
      const visibleValue = element.dataset.sensitiveChartVisibleValue || element.textContent
      const maskedValue = element.dataset.sensitiveChartMaskedValue || "••••••"
      element.textContent = isHidden ? maskedValue : visibleValue
      if (element.hasAttribute("aria-label")) element.setAttribute("aria-label", isHidden ? "Valor financeiro oculto" : visibleValue)
      if (element.hasAttribute("title")) element.setAttribute("title", isHidden ? "Valor financeiro oculto" : visibleValue)
    })

    document.querySelectorAll("[data-sensitive-chart-title]").forEach((element) => {
      element.setAttribute("title", isHidden ? "Valores financeiros ocultos" : element.dataset.sensitiveChartTitle)
    })

    toggles.forEach((toggle) => {
      const icon = toggle.querySelector("[data-privacy-toggle-icon]")
      const label = toggle.querySelector("[data-privacy-toggle-label]")
      toggle.setAttribute("aria-pressed", String(isHidden))
      toggle.setAttribute("aria-label", isHidden ? "Mostrar valores financeiros" : "Ocultar valores financeiros")
      toggle.title = isHidden ? "Mostrar valores financeiros" : "Ocultar valores financeiros"
      icon?.classList.toggle("fa-eye", !isHidden)
      icon?.classList.toggle("fa-eye-slash", isHidden)
      if (label) label.textContent = isHidden ? "Mostrar valores" : "Ocultar valores"
    })
  }

  const hidden = window.localStorage.getItem(PRIVACY_MODE_STORAGE_KEY) === "hidden"
  toggles.forEach((toggle) => {
    if (toggle.dataset.privacyInitialized === "true") return
    toggle.dataset.privacyInitialized = "true"
    toggle.addEventListener("click", () => {
      const nextState = document.documentElement.dataset.privacyMode !== "hidden"
      window.localStorage.setItem(PRIVACY_MODE_STORAGE_KEY, nextState ? "hidden" : "visible")
      applyPrivacyMode(nextState)
    })
  })
  applyPrivacyMode(hidden)
}

document.addEventListener("turbo:load", initializePrivacyMode)
