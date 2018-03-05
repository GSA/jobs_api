# frozen_string_literal: true

class PositionOfferingType
  CODES = { permanent: 15_317, temporary: 15_318, term: 15_319, detail: 15_320,
            temporary_promotion: 15_321, seasonal: 15_322, summer: 15_323,
            presidential_management_fellows: 15_324, recent_graduates: 15_326,
            multiple_appointment_types: 15_327, internships: 15_328,
            intermittent: 15_522, ictap_only: 15_667, agency_employees_only: 15_668,
            telework: 15_669 }.freeze

  def self.get_code(name)
    CODES[normalize_name(name)]
  end

  def self.normalize_name(name_str)
    name = name_str.downcase.gsub('- ', '').gsub(/(full|part)([- ])?time/, '').squish
    case name
    when /(?:^|\s)perm(anent)?\b/ then :permanent
    when /\bseasonal\b/ then :seasonal
    when /\btemporary promotion\b/ then :temporary_promotion
    when /\bfte|(career|civil) service\b/ then :permanent
    when /\btemp(orary)?\b/ then :temporary
    when /\bintern(ship)?s?\b/ then :internships
    when /\bterm\b/ then :term
    else name.tr(' ', '_').to_sym
    end
  end
end
