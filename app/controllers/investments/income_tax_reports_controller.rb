class Investments::IncomeTaxReportsController < ApplicationController
  def show
    @report_year = permitted_report_year(params[:year])
    @available_years = available_report_years
    @report = Investments::IncomeTaxReportBuilder.call(
      incomes: policy_scope(Investments::Income),
      year: @report_year
    )
  end

  private

  def permitted_report_year(value)
    year = Integer(value, exception: false)
    return year if year&.between?(1900, Date.current.year)

    Date.current.year
  end

  def available_report_years
    first_year = policy_scope(Investments::Income).minimum(:payment_date)&.year || Date.current.year

    (first_year..Date.current.year).to_a.reverse
  end
end
