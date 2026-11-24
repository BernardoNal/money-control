module AccountHelpers
  def test_bank(name)
    code = "spec-#{name.parameterize}"
    BankInstitution.find_or_create_by!(source: "spec", bank_code: code) do |bank|
      bank.name = name
      bank.short_name = name
    end
  end
end
