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
    panels.forEach((panel) => panel.classList.toggle("hidden", panel.dataset.tabPanel !== tab))
    buttons.forEach((button) => {
      const active = button.dataset.tabButton === tab
      button.classList.remove(...activeClasses, ...inactiveClasses)
      button.classList.add(...(active ? activeClasses : inactiveClasses))
    })
    if (hiddenField) hiddenField.value = tab

    const params = new URLSearchParams(window.location.search)
    params.set("tab", tab)
    const queryString = params.toString()
    window.history.replaceState({}, "", queryString.length > 0 ? `${window.location.pathname}?${queryString}` : window.location.pathname)
  }

  buttons.forEach((button) => button.addEventListener("click", () => setTab(button.dataset.tabButton)))
  setTab(root.dataset.initialTab || "overview")
}

document.addEventListener("turbo:load", initializePortfolioTabs)
