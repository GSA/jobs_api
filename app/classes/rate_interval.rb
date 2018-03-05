# frozen_string_literal: true

class RateInterval
  CODES = { bi_weekly: 'BW',
            fee_basis: 'FB',
            per_year: 'PA',
            per_day: 'PD',
            per_hour: 'PH',
            per_month: 'PM',
            piece_work: 'PW',
            student_stipend_paid: 'ST',
            school_year: 'SY',
            without_compensation: 'WC' }.freeze

  def self.get_code(name)
    CODES[parse(name)]
  end

  def self.parse(name)
    name_str = name.squish.underscore.tr(' ', '_')
    case name_str
    when /^day$/ then :per_day
    when /^year$/ then :per_year
    when /^month(ly)?$/ then :per_month
    when /^hour(ly)?$/ then :per_hour
    else name_str.to_sym
    end
  end
end
