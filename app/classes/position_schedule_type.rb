# frozen_string_literal: true

class PositionScheduleType
  CODES = { full_time: 1, part_time: 2, shift_work: 3, intermittent: 4, job_sharing: 5, multiple_schedules: 6 }.freeze

  def self.get_code(name)
    CODES[name.sub(' ', '-').underscore.to_sym]
  end
end
