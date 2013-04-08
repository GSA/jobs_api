class PositionOfferingType
  CODES = {permanent: 15317, temporary: 15318, term: 15319, detail: 15320,
           temporary_promotion: 15321, seasonal: 15322, summer: 15323,
           presidential_management_fellows: 15324, recent_graduates: 15326,
           multiple_appointment_types: 15327, internships: 15328,
           intermittent: 15522, ictap_only: 15667, agency_employees_only: 15668,
           telework: 15669}.freeze

  def self.get_code(name)
    CODES[normalize_name(name)]
  end

  private

  def self.normalize_name(name_str)
    name = name_str.downcase.squish
    case name
      when /\b(permanent|seasonal)\b/ then "#{$1}".to_sym
      when /\bintern(ship)?s?\b/i then :internships
      else name.gsub(/ /, '_').to_sym
    end
  end
end