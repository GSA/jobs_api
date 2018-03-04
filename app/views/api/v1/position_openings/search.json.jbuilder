# frozen_string_literal: true

json.array! @position_openings do |position_opening|
  json.id position_opening[:external_id].to_s
  json.call(position_opening, :position_title, :organization_name, :rate_interval_code, :minimum, :maximum, :start_date, :end_date, :locations)
end
