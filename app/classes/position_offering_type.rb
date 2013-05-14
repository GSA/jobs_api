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
    name = name_str.downcase.gsub('- ','').gsub(/(full|part)([- ])?time/,'').squish
    case name
      when /(?:^|\s)perm(anent)?\b/ then :permanent
      when /\bseasonal\b/ then :seasonal
      when /\btemporary promotion\b/ then :temporary_promotion
      when /\bfte|(career|civil) service\b/ then :permanent
      when /\btemp(orary)?\b/ then :temporary
      when /\bintern(ship)?s?\b/ then :internships
      when /\bterm\b/ then :term
      else name.gsub(/ /, '_').to_sym
    end
  end
end