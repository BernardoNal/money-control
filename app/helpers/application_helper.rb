module ApplicationHelper
  def primary_navigation_items
    [
      { label: "Dashboard", path: root_path, icon: "fa-solid fa-chart-line", active: -> { controller_path == "transactions" && action_name == "dashboard" } },
      { label: "Contas", path: accounts_path, icon: "fa-solid fa-wallet", active: -> { controller_path == "accounts" } },
      { label: "Transacoes", path: transactions_path, icon: "fa-solid fa-arrow-right-arrow-left", active: -> { controller_path == "transactions" && action_name != "dashboard" } },
      { label: "Categorias", path: categories_path, icon: "fa-solid fa-layer-group", active: -> { controller_path == "categories" } }
    ]
  end

  def investments_navigation_items
    [
      { label: "Portfolios", path: investments_portfolios_path, icon: "fa-solid fa-chart-pie", active: -> { controller_path.start_with?("investments/portfolios") } },
      { label: "Ativos", path: investments_assets_path, icon: "fa-solid fa-coins", active: -> { controller_path.start_with?("investments/assets") } },
      { label: "Recebiveis", path: investments_incomes_path, icon: "fa-solid fa-hand-holding-dollar", active: -> { controller_path.start_with?("investments/incomes") } }
    ]
  end

  def navigation_item_classes(item)
    base_classes = "inline-flex items-center gap-2 rounded-full px-4 py-2 text-sm font-medium no-underline transition"

    if item[:active].call
      "#{base_classes} bg-white text-slate-950 shadow-sm"
    else
      "#{base_classes} bg-slate-900 text-slate-300 ring-1 ring-slate-700 hover:bg-slate-800 hover:text-white"
    end
  end

  def flash_banner_classes(type)
    case type.to_sym
    when :notice
      "border-emerald-200 bg-emerald-50/90 text-emerald-800"
    when :alert
      "border-amber-200 bg-amber-50/95 text-amber-900"
    else
      "border-slate-200 bg-white/95 text-slate-700"
    end
  end

  def user_initials(user)
    user.name.to_s.split.map { |part| part[0] }.first(2).join.upcase.presence || "MC"
  end

  def user_display_name(user)
    source = user.name.presence || user.email.to_s.split("@").first
    source.to_s.split.first(2).join(" ")
  end
end
